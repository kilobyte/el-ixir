// El-Ixir game, by Castamir.
// Separated from the real room to protect the mental health of readers.

#pragma optimize
#include <mudlib.h>

inherit ROOM;

#define DEBUG /* extra callable functions and consistency checks */

#define OFF 1		 /* the in-memory border */
#define TS 14+2*OFF      /* board size */
#define CORNGLYPH 3	 /* the first corner glyph in the glyphs table */
#define MOVEGLYPH 6      /* the first move glyph in the glyphs table */
#define CORN_MASK 0x2001 /* the bitmask for the corner tiles */
#define GOOD_CLIENTS ({ "zmud","kbtin","linux","mushclient" })
/*
We check only the first TERM string, it's tricky to check the rest
from outside the connection object.

Common strings:
    vt100       (true vt100 at least) doesn't support any colors
    ansi        is abused by everyone and their dog
    xterm       should be safe, but it's still abused sometimes
    linux       supports bg colors, and is AFAIK not abused by anything
    kbtin       supports bg colors since 0.3.0 (ancient version)
    zmud        supports bg colors since some unknown ancient version
    mushclient  supports bg colors at least in all versions I checked
*/

mixed *glyphs=({ ({     // no colors
                 "._.","[X]","(O)",
                 ".*.","<X>","<O>",
                 ":a:",":b:",":c:",":d:",
                }), ({  // client capabilities not known
                 "._.","$CYN$[X]$0$","$HIM$[O]$0$",
                 ".*.","$CYN$<X>$0$","$HIM$<O>$0$",
                 "$BOLD$(a)$0$","$BOLD$(b)$0$","$BOLD$(c)$0$","$BOLD$(d)$0$",
                }), ({  // clients known to support bg colors
                 "._.", "\e[35;46m + \e[0m", "\e[35;45;1m + \e[0m",
                 ".*.", "\e[35;46m<*>\e[0m", "\e[35;45;1m<*>\e[0m",
                 "\e[0;37;1m(a)\e[0m", "\e[0;37;1m(b)\e[0m",
                 "\e[0;37;1m(c)\e[0m", "\e[0;37;1m(d)\e[0m",
                }) });
mixed *testdata=({ ({ 5, 0, 2, 1 }),
                   ({ 2, 0, 2, 2 }),
                   ({ 2, 1, 6, 2 }),
                   ({ 3, 1, 0, 2 }) });
string *col=({"$CYN$","$HIM$"});

int *bitcnt;
int gameid=0;
mixed *board;       // the board as two bitmasks, for 1st and 2nd player
int *bitmap,*bitmask;
mixed *unpacked;
mapping games;


void create()
{
    int i;

    ::create();
    set("short", "the el-ixir game");
    set("long", @EndText
Blargh blargh, "look boards", "read rules".
EndText);
    set("item_desc", ([
            "board"     : "@@look_board",
            "boards"    : "@@look_boards",
            "rules"     : @EndText
    An old yellowish scroll labelled "Rules" stands rolled near the boards
box.  If you wanted to play a game, it might be a good idea to read it first.
EndText,
            "box"       : @EndText
    An open wooden box contains a number of game boards.  If you want to
use them, just 'play with friend' or even 'play with myself'.
EndText,
        ]));
    add("item_desc", ([
            "scroll"    : query("item_desc/rules"),
            "boards box": query("item_desc/box"),
        ]));
    set("take_fail", ([
            "rules"     : @EndText
    Just think: if you took the scroll, no newbies would be able to play;
and newbies are the only people you can beat.  So, leaving the rules intact
lies in your interest, if you ever want to win against someone.
EndText,
            "block"     : "A single game block is pretty worthless.\n",
            "board"     : "No way, buddy.\n",
    	]));
    add("take_fail", ([
            "scroll"    : query("take_fail/rules"),
        ]));
    games=([]);
    users()->delete_temp("el-ixir:gameid"); // better than no clean_up
}


void init()
{
    add_action("_play",      "play");
    add_action("_surrender", "surrender");
    add_action("_place",     "place");
    add_action("_observe",   "observe");
    add_action("_read",	     "read");
}


#ifdef DEBUG
string hexid(int* m)
{
    string out="[";
    int i;
    
    foreach(i in m)
        out+=sprintf("%x,",i);
    return out[0..<2]+"]";
}


void print_bitmaps(int *b1, int *b2)
{
    int i,j;
    string out="----------------------------------\n";
    for(i=OFF;i<14+OFF;i++)
    {
        out+="\t";
        for(j=0;j<14;j++)
            out+=({ ".","$HIR$?$0$","$GRN$x$0$","$BOLD$X$0$" })
                [((b1[i]&(1<<j))?1:0)+((b2[i]&(1<<j))?2:0)];
        out+="\n";
    }
    write(out);
}
#endif


/*
The most time consuming function.
It's equivalent to a BFS on the unpacked data, but a lot faster (O(n) in the
average case as opposed to O(n^2) of BFS, still O(n^2) in the pessimistic case
but with a smaller constant factor.

It extends the bitmap to all adjacent squares, within boundaries defined by
the mask.
*/
void flood(int *bitmap, int *mask, int diag)
{
    int cur,next;
    int o,n;

    next=OFF;
    while((cur=next++)<14+OFF)
    {
        o=bitmap[cur];
        while(1)    //damn I want goto in LPC
        {
            n=(o<<1 | o>>1)&mask[cur];      // extend to the sides
            if ((o|n)!=o)
                bitmap[cur]=(o|=n);
            else
                break;
        }
        if (diag)
            o|=o<<1 | o>>1;
        bitmap[cur+1]|=o&mask[cur+1];       // extend downwards
        n=o&mask[cur-1];
        o=bitmap[cur-1];
        if ((o|n)!=o)
        {
            bitmap[cur-1]|=n;               // extend upwards
            next=cur-1;                     // ... and back off to that line
        }
    }
}


// Count all anchored blocks for player <pln>.
int get_score(int pln)
{
    int i,sum;
    
    for(i=0;i<TS;i++)
        bitmap[i]=0;
    bitmap[ 0+OFF]=board[pln][ 0+OFF]&CORN_MASK;
    bitmap[13+OFF]=board[pln][13+OFF]&CORN_MASK;
    if (!bitmap[ 0+OFF]&&!bitmap[13+OFF])
        return 0;
    flood(bitmap, board[pln], 0);
    sum=0;
    for(i=OFF;i<14+OFF;i++)
        sum+=bitcnt[bitmap[i]&127]+bitcnt[bitmap[i]>>7];
    return sum;
}


int complete_embrace(int pln)
{
    int i;
    int flag=0;
    
    for(i=0;i<TS;i++)
        bitmap[i]=bitmask[i]=0;
    for(i=OFF;i<14+OFF;i++)
        bitmask[i]=~board[pln][i]&0x3fff;
    bitmap[ 0+OFF]=bitmask[ 0+OFF]&CORN_MASK;
    bitmap[13+OFF]=bitmask[13+OFF]&CORN_MASK;
    flood(bitmap, bitmask, 1);
    for(i=OFF;i<14+OFF;i++)
        if (bitmap[i]=~(bitmap[i]|board[pln][i])&0x3fff)
        {
            flag=1;
            board[pln][i]|=bitmap[i];
            board[!pln][i]&=~bitmap[i];
        }
    return flag;
}


int anchor_embrace(int pln)
{
    int i;
    int flag=0;
    
    for(i=0;i<TS;i++)
        bitmap[i]=bitmask[i]=0;
    for(i=OFF;i<14+OFF;i++)
        bitmask[i]=~board[pln][i]&0x3fff;
    for(i=OFF;i<14+OFF;i++)
        bitmap[i]=~(board[0][i]|board[1][i])&0x3fff;
    bitmap[ 0+OFF]|=bitmask[ 0+OFF]&CORN_MASK;
    bitmap[13+OFF]|=bitmask[13+OFF]&CORN_MASK;
    flood(bitmap, bitmask, 0);
    for(i=OFF;i<14+OFF;i++)
        bitmask[i]=~bitmap[i]&0x3fff;
    for(i=0;i<TS;i++)
        bitmap[i]=0;
    bitmap[ 0+OFF]=board[pln][ 0+OFF]&CORN_MASK;
    bitmap[13+OFF]=board[pln][13+OFF]&CORN_MASK;
    flood(bitmap, bitmask, 0);
    for(i=OFF;i<14+OFF;i++)
        if (bitmap[i]=bitmap[i]&~board[pln][i])
        {
            flag=1;
            board[pln][i]|=bitmap[i];
            board[!pln][i]&=~bitmap[i];
        }
    return flag;
}


// Generate an array of up to 4 valid moves.
mixed roll_moves()
{
    int i,j,roll,total;
    mixed moves=({});

    for(i=OFF;i<14+OFF;i++)     // get all the free squares
        bitmap[i]=~(board[0][i]|board[1][i])&0x3fff;
    total=0;
    for(i=OFF;i<14+OFF;i++)     // count them
        total+=bitmask[i]=bitcnt[bitmap[i]&127]+bitcnt[bitmap[i]>>7];
    if (!total)
        return 0;
    while(total && sizeof(moves)<4)
    {
        roll=random(total);
        for(i=OFF;i<14+OFF;i++) // search for the row the rolled square is in
        {
            if ((roll-=bitmask[i])>=0)
                continue;
            j=bitcnt[bitmap[i]>>7]; // no. of free squares in the right half
            if (roll+j>=0)
                j=14;           // right half
            else
                roll+=j, j=7;   // left half
            while(roll<0)
                if (bitmap[i]&(1<<--j))
                    roll++;
            moves+=({ ({i-OFF,j}) });
            bitmap[i]&=~(1<<j);
            total--;
            bitmask[i]--;
            break;
        }
    }
    return moves;
}


// return the board as a string
// Note: it lacks the final "\n".
string draw_board(object pl, int id)
{
    int i,j;
    mixed m;
    string scores;
    int glset;

#ifdef DEBUG
    for(i=0;i<TS;i++)
        if (board[0][i]&board[1][i])
            return "Board is inconsistent!";
#endif
    if (pl->query_env("color")!="on")
        glset=0;
    else if (!pl->query_link() || !(m=pl->query_link()->query_ttype())
        || member_array(lower_case(m), GOOD_CLIENTS)==-1)
        glset=1;
    else
        glset=2;

    scores=sprintf(glset?
            "$CYN$%s (%d)$0$ vs $HIM$%s (%d)%s\n\t":
            "%s (%d) vs %s (%d)\n\t",
        games[id]["names"][0], games[id]["score"][0],
        games[id]["names"][1], games[id]["score"][1],
        "\e[0m" /* to kill color/item_desc */);
    for(i=0;i<14;i++)
        for(j=0;j<14;j++)
            unpacked[i+OFF][j+OFF]=(board[0][i+OFF]&(1<<j))? 1 :
                                   (board[1][i+OFF]&(1<<j))? 2 :
                                   0;
    unpacked[ 0+OFF][ 0+OFF]+=CORNGLYPH;
    unpacked[ 0+OFF][13+OFF]+=CORNGLYPH;
    unpacked[13+OFF][ 0+OFF]+=CORNGLYPH;
    unpacked[13+OFF][13+OFF]+=CORNGLYPH;
    if (games[id]["moves"])
    {
        i=MOVEGLYPH;
        foreach(m in games[id]["moves"])
            unpacked[m[0]+OFF][m[1]+OFF]=i++;
    }
    return scores+implode(map_array(unpacked[OFF..OFF+13],
        (: implode(map_array($1[OFF..OFF+13], (: $(glyphs[$(glset)])[$1] :)),"") :)),
        "\n\t");
}


// Show the board to everyone interested in the room.
void show_board(int id)
{
    object pl;
    string str;
    int pln;
    
    foreach(pl in all_inventory(this_object()))
        if (interactive(pl) && pl->query_temp("el-ixir:gameid")==id)
        {
            str=draw_board(pl, id);
            if (games[id]["players"] && !undefinedp(pln=games[id]["pln"])
                && pl==games[id]["players"][pln])
                str+="\nIt's your turn, "+col[pln]
                    +games[id]["names"][pln]+"$0$!\n";
            else
                str+="\n";
            tell_object(pl, str);
        }
}


// Write a message to all observers.
void show_message(int id, string msg)
{
    int pln;
    object pl,pl1,pl2;
    
    pln=games[id]["pln"];
    pl1=games[id]["players"][pln];
    pl2=games[id]["players"][!pln];
    
    foreach(pl in all_inventory(this_object()))
        if (interactive(pl) && pl->query_temp("el-ixir:gameid")==id)
            tell_object(pl, replace_string(replace_string(replace_string(msg,
                "#N", (pl1==pl)?"You":col[pln]+pl1->query("cap_name")+"$0$"),
                "#1", (pl1==pl)?"":"s"),
                "#n", (pl1==pl2)?"the "+col[!pln]+"other$0$ side":
                    (pl2==pl)?"you":col[!pln]+pl2->query("cap_name")+"$0$"));
}


void init_game(object pl1, object pl2)
{
    int i,j;
    mixed game=([]);
    string victim=(pl1==pl2)? "self" : "#n";

    foreach(i in keys(games))
        if (games[i]["result"])
        {
            map_delete(games, i);
            j++;
        }
    if (j)
        emote(pl1, replace_string(@EndText
#N #Vclear the used board, and #Vprepare it for a game against #n.
EndText,"#n",victim), 0, pl2);
    else
        emote(pl1, replace_string(@EndText
    #N #Vpull out an El-Ixir board and a set of blocks from the box,
preparing them for a game against #n.
EndText,"#n",victim), 0, pl2);
                
    if (!unpacked)
    {
        unpacked=allocate(TS);
        for(i=0;i<TS;i++)
            unpacked[i]=allocate(TS);
        bitcnt=allocate(128);
        for(i=0;i<128;i++)
            bitcnt[i]=(i&1)+((i&2)>>1)+((i&4)>>2)+((i&8)>>3)+((i&16)>>4)+((i&32)>>5)+((i&64)>>6);
        bitmap=allocate(TS);
        bitmask=allocate(TS);
    }
    game["players"]=({ pl1,pl2 });
    game["names"]=({ pl1->query("cap_name"),pl2->query("cap_name") });
    game["board"]=board=({ allocate(TS),allocate(TS) });
    game["pln"]=random(2);
    game["moves"]=roll_moves();
    game["score"]=({ 0,0 });
    games[++gameid]=game;
    pl1->set_temp("el-ixir:gameid",gameid);
    pl2->set_temp("el-ixir:gameid",gameid);
    show_board(gameid);
}


string observable()
{
    string str;
    object *players;
    int id,any;

    if (sizeof(games))
    {
        str="The games you can 'observe' are:\n";
        foreach(id in keys(games))
            if (players=games[id]["players"])
            {
                str+=sprintf(" %s vs %s\n", players[0]->query("cap_name"),
                    players[1]->query("cap_name"));
                any++;
            }
    }
    if (!any)
        str="No one is playing at this moment.\n";
    
    return str;
}


string look_boards()
{
    return observable()+@EndText

You can:
 'play with someone'   to propose a game to Someone
 'observe someone'     to watch the game Someone is playing
 'read rules'          to read the rules of El-Ixir
EndText;
}


string look_board()
{
    string str;
    object *players,pl;
    int pln,id=this_player()->query_temp("el-ixir:gameid");
    
    if (id && games[id])
    {
        board=games[id]["board"];
        str=draw_board(this_player(), id);
        if (players=games[id]["players"])
            pl=players[pln=games[id]["pln"]];
        if (pl)
            if (pl==this_player())
                return sprintf("%s\nIt's your turn, %s%s$0$.\n", str,
                    col[pln], pl->query("cap_name"));
            else
                return sprintf("%s\nIt's %s%s$0$ turn.\n", str,
                    col[pln], apostrophed(pl->query("cap_name")));
        else
            return sprintf("%s\nThe game is over, %s.\n", str, games[id]["result"]);
    }
    return look_boards();
}


int _play(string str)
{
    object opp;
    int id;

    if (!this_player()->query_vision())
        return notify_fail("You can't see!\n");
    if (!str)
    {
        str=this_player()->query_temp("el-ixir:last_challenger");
        if (str)
            str="with "+str;
    }
    if (!str
        || !sscanf(str, "with %s", str)
        && !sscanf(str, "against %s", str))
        return notify_fail("Play with whom?\n");
    if (str=="me" || str=="myself")
        str=this_player()->query("name");
    opp=present(str, this_object());
    if (!opp || !userp(opp) || !visible(opp, this_player()))
        return notify_fail("There is no player here by that name.\n");
    if (!interactive(opp))
        return notify_fail("Linkdead people tend to be boring opponents, you know.\n");
    if (!visible(this_player(), opp))
        return notify_fail("You would need to reveal yourself first.\n");
    id=this_player()->query_temp("el-ixir:gameid");
    if (games[id] && !games[id]["result"]
        && member_array(this_player(),games[id]["players"])!=-1)
        return notify_fail("You're already playing, finish up the game or surrender first.\n");
    id=opp->query_temp("el-ixir:gameid");
    if (games[id] && !games[id]["result"]
        && member_array(opp,games[id]["players"])!=-1)
        return notify_fail(opp->query("cap_name")+" is already playing another game.\n");
    if (opp!=this_player() && opp->query_temp("el-ixir:challenged")!=this_player())
    {
        this_player()->set_temp("el-ixir:challenged", opp);
        opp->set_temp("el-ixir:last_challenger", this_player());
        msg("#N #Vpropose a game of El-Ixir to #n.\n", 0, opp, @EndText
#N proposes you a game of El-Ixir.  Type 'play' to accept.
EndText);
        return 1;
    }
    opp->delete_temp("el-ixir:challenged");
    opp->set_temp("el-ixir:last_challenger", this_player());
    this_player()->delete_temp("el-ixir:challenged");
    this_player()->set_temp("el-ixir:last_challenger", opp);
    init_game(this_player(), opp);
    return 1;
}


int _accept(string str)
{
    if (str)
        return notify_fail("Just 'accept'.\n");
    if (this_player()->query_temp("el-ixir:last_challenger"))
        return _play(0);
}


int _surrender(string str)
{
    int id;

    if (str && str!="game" && str!="the game")
        return notify_fail("Surrender what?\n");
    if (!(id=this_player()->query_temp("el-ixir:gameid")))
        return notify_fail("You're not playing a game.\n");
    if (!games[id])
        return notify_fail("That game is over and already packed up!\n");
    if (games[id]["result"])
        return notify_fail("That game is already over!\n");
    if (member_array(this_player(),games[id]["players"])==-1)
        return notify_fail("You're just observing, you can't surrender someone else's game.\n");
    map_delete(games[id],"moves");
    map_delete(games[id],"players");
    games[id]["result"]=this_player()->query("cap_name")+" surrendered";
    // Can't use emote() here when called from object_left().
    // We can't do this from release_object() as plenty of things do
    // things like player->move(environment(player)).
    write("You surrender your game.\n");
    tell_room(this_object(), "$N surrenders "+possessive(this_player())
        +" game.\n", ({ this_player() }));
    return 1;
}


void object_left(object pl)
{
    if (userp(pl) && !present(pl,this_object()))
        _surrender(0);
    if (!sizeof(games))     // conserve the memory
    {
        board=0;
        unpacked=0;
        bitcnt=0;
        bitmap=0;
        bitmask=0;
    }
}


void end_game(int id)
{
    object *players, winner;
    string wname, wcolor;
    int *score;
    object *obs;

    map_delete(games[id],"moves");
    map_delete(games[id],"pln");
    show_board(id);
    score=games[id]["score"];
    players=games[id]["players"];
    if (score[0]>score[1])
        winner=players[0], wcolor="$CYN$";
    else if (score[0]<score[1])
        winner=players[1], wcolor="$HIM$";
    obs=filter_array(all_inventory(this_object()),
       (: interactive($1)&& $1->query_temp("el-ixir:gameid")==$(id) :));
    if (players[0]!=players[1])
    {
        if (winner)
        {
            games[id]["result"]=wcolor+(wname=
                winner->query("cap_name"))+"$0$ won";
            tell_object(winner, "$HIR$\nYou won the game!\n$0$\n");
            message("tell_object", "$HIR$\n"+wname+" won the game!\n$0$\n",
                obs, winner);
            tell_room(this_object(),wname+" wins a game against "+
                ((winner==players[0])?players[1]:players[0])
                ->query("cap_name")+".\n");
        }
        else
        {
            games[id]["result"]="it was a draw";
            message("tell_object", "$HIB$\nIt's a draw!\n$0$\n", obs);
            tell_room(this_object(),"A game between "
                +players[0]->query("cap_name")+" and "
                +players[1]->query("cap_name")+" ends in a draw.\n", obs);
        }            
    }
    else            // a solitary game
    {
        if (winner)
        {
            games[id]["result"]=wcolor+(wname=
                winner->query("cap_name"))+"$0$ won";
            message("tell_object", wcolor+wname+" won!\n", obs);            
        }
        else
        {
            games[id]["result"]="it was a draw";
            message("tell_object", "$HIB$\nIt's a draw!\n$0$\n", obs);
        }
        say("$N finishes a solitary game.\n", obs);
    }
    map_delete(games[id],"players");
}


int _place(string str)
{
    int id;
    string move,dir,msg;
    int pln,len,tx,ty,x,y,dx,dy,poss,i;
    mixed *moves,*score;
    int mce,mae,oae;
    
    if (!(id=this_player()->query_temp("el-ixir:gameid")))
        return notify_fail("You're not playing a game.\n");
    if (!games[id])
        return notify_fail("That game is over and already packed up!\n");
    if (games[id]["result"])
        return notify_fail("That game is already over!\n");
    if (member_array(this_player(),games[id]["players"])==-1)
        return notify_fail("You're observing the game, not playing.\n");
    if (this_player()!=games[id]["players"][pln=games[id]["pln"]])
        return notify_fail("It's not your turn!\n");
    board=games[id]["board"];
    if (!str)
        return notify_fail("Syntax: place <letter> <dir> [<length>]\n");
    if (sscanf(str, "%s %s", move, dir)<2)
        dir="", move=str;
    if (sscanf(dir, "%s %d", dir, len)<2)
        len=0;
    move=lower_case(move);
    moves=games[id]["moves"];
    if (strlen(move)!=1 || move[0]<'a' || move[0]>='a'+sizeof(moves))
        return notify_fail(sprintf("Valid moves are named a..%c.\n",
            'a'-1+sizeof(moves)));
    ty=y=moves[move[0]-'a'][0]+OFF;
    tx=x=moves[move[0]-'a'][1];
    for(i=0;i<TS;i++)
        bitmask[i]=0;
    for(i=OFF;i<14+OFF;i++)
        bitmask[i]=~(board[0][i]|board[1][i])&0x3fff;
    if (bitmask[y-1]&(1<<x))      poss++;
    if (bitmask[y+1]&(1<<x))      poss++;
    if (bitmask[y]&(1<<(x-1)))    poss++;
    if (bitmask[y]&(1<<(x+1)))    poss++;
    if (poss=0)
        len=1;          // special case: a lone square
    else
        switch(dir)
        {
        case "up":
        case "u":
        case "north":
        case "n":
            dx=0; dy=-1; break;
        case "down":
        case "d":
        case "south":
        case "s":
            dx=0; dy=1; break;
        case "left":
        case "l":
        case "west":
        case "w":
            dx=-1; dy=0; break;
        case "right":
        case "r":
        case "east":
        case "e":
            dx=1; dy=0; break;
        default:
            return notify_fail("Invalid direction!\n");
        }
    for(poss=0;poss<len;poss++)
    {
        if (!(bitmask[y]&(1<<x)))
            return notify_fail("That block will not fit there!\n");
        x+=dx;
        y+=dy;
    }
    x=tx, y=ty;
    if (!len)
        len=4;
    while(len--)
    {
        if (!(bitmask[y]&(1<<x)))
            break;
        board[pln][y]|=1<<x;
        x+=dx;
        y+=dy;
    }
    mce=complete_embrace(pln);
    oae=anchor_embrace(!pln);
    mae=anchor_embrace(pln);
    score=({ get_score(0),get_score(1) });
    msg=({});
    if (mce)
        msg=({"complete#1 an embrace"});
    if (oae)
        msg+=({"let#1 #n anchor "+(mce?"one":"an embrace")});
    if (mae)
        if (mce||oae)
            msg+=({"anchor#1 another one"});
        else
            msg+=({"anchor#1 an embrace"});
    if (!sizeof(msg) && score[pln]!=games[id]["score"][pln])
        msg=({"anchor#1 a chain"});
    if (sizeof(msg))
        show_message(id, "#N "+format_array(msg)+".\n");
    games[id]["pln"]=pln=!pln;
    games[id]["moves"]=moves=roll_moves();
    games[id]["score"]=score;
    if (score[0]>98 || score[1]>98 || !sizeof(moves))
        end_game(id);
    else
        show_board(id);
    return 1;
}


#ifdef DEBUG
// call here;testglyphs
// - or -
// call here;testglyphs;draugluin
void testglyphs(object pl)
{
    string str="";
    mixed line;
    int glset;
    foreach(line in testdata)
    {
        for(glset=0;glset<3;glset++)
            str+="\t"+implode(map_array(line, (: $(glyphs[glset])[$1] :)),"");
        str+="\n";
    }
    if (pl)
        tell_object(pl, str);
    else
        write(str);
}
#endif


int _observe(string str)
{
    object opp;
    int id;

    if (!this_player()->query_vision())
        return notify_fail("You can't see!\n");
    if (!str)
    {
        if (this_player()->query_temp("el-ixir:gameid"))
        {
            this_player()->delete_temp("el-ixir:gameid");
            write("You stop observing.\n");
            return 1;
        }
        write(observable());
        return 1;
    }
    opp=present(str, this_object());
    if (!opp || !userp(opp) || !visible(opp, this_player()))
        return notify_fail("There is no player here by that name.\n");
    id=this_player()->query_temp("el-ixir:gameid");
    if (games[id] && !games[id]["result"]
        && member_array(this_player(),games[id]["players"])!=-1)
        return notify_fail("You're playing a game, finish it up or surrender first.\n");
    id=opp->query_temp("el-ixir:gameid");
    if (!games[id])
        return notify_fail("That person is neither playing nor watching any game.\n");
    this_player()->set_temp("el-ixir:gameid", id);
    if (games[id]["result"])
        msg("",     // look_board will mention the game is over
        "#N #Vstand behind #g shoulder, analyzing the ending position of the game.\n",
        opp);
    else if (member_array(opp,games[id]["players"])!=-1)
        msg("You start watching #g game.\n",
            "#N #Vstand behind #g shoulder, watching #g game.\n",
            opp);
    else
        msg("You stand behind #g shoulder, joining the crowd watching the game.\n",
            "#N #Vstand behind #g shoulder, watching the game.\n",
            opp, 0, 0, 1);
    write(look_board());
    return 1;
}


int _read(string str)
{
    if (str!="rules" && str!="scroll")
        return notify_fail("Read what?  The rules?\n");
    this_player()->more(explode(@EndText
You take the scroll, unroll it and start reading...

      El-Ixir is a two-player game (although it is possible to play
  against yourself); to propose a game to someone type 'play with XXX'.
  You can also 'observe XXX' to watch the game played by that person.
      The object of the game is to connect as much of blocks in your
  colour to the corners.  The players take turns, rolling the ????s...
  
A notch in the scroll's edge leaves only a single tengwa of this word.
To make it worse, the whole next section seems to be quite complicated.
You skip it, hoping you'll catch the rolling rules during the play.

    MOVING: To make a move, choose one of the four tiles you just rolled,
    and 'place tile dir' or 'place tile dir length', where 'tile' is the
    letter (a-d) that marks the tile you've chosen, dir is the direction
    to position your block (up, left, right, down -- or n, w, s, e), and
    length (1-4) is the block you want to use; if you don't specify a
    length, the longest block that fits will be used.

    ANCHORING: If the block you placed causes some blocks to be connected
    to one of the corners, you will be credited a point for every tile
    covered by a block in your color that's connected to one of the corners.

    EMBRACING: There are two types of embraces:
    - complete embrace, when your blocks either completely enclose a part
      of the board or wall it in into a border
    - anchored embraces, which trade the requirement of enclosing only
      parts of the board that contain no free tiles for allowing braces
      that are connected only diagonally

Whichever player gets the most points, wins.
EndText,"\n"));
    return 1;
}
