{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}
{

Copyright 2007 Jakob Dangarden

 This file is part of Usurper.

    Usurper is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    Usurper is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Usurper; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
}



Unit HealerC; {Usurper - Healing Hut}

Interface

Procedure Healer;

Implementation

Uses Init, Cms, Jakob,
     Invent, News, Statusc,
     Various, Various2, Online,
     File_Io;

const manager = 'Jadu';

var refresh : boolean;
    justval : byte;

Procedure Meny;
begin
 clearscreen;
 crlf;
 d(5,'-*- The Golden Bow, Healing Hut -*-');
 crlf;
 d(config.textcolor,manager+' The Fat is sitting at his desk, reading a book.');
 d(config.textcolor,'He is wearing a monks robe and a golden ring.');

 crlf;
 justval:=24;

 menu('(H)eal Disease');
 menu('(C)ursed item removal');
 menu('(S)tatus');
 menu('(R)eturn to street');

end;

Procedure Display_Menu(force,short : boolean);
begin

 {sethotkeys_on(NoKill,['H',
                       'C',
                       'R',
                       'S',
                       '?']);}

 if short=true then begin
  if player.expert=false then begin
   if (refresh) and (player.auto_meny) then begin
    refresh:=false;
    meny;
   end;

   if player.ear=1 then begin
    who_is_here;
   end;

   crlf;
   sd(config.textcolor,'Healing Hut (');
   sd(config.hotkeycolor,'?');
   sd(config.textcolor,' for menu) :');
  end
  else begin
   if player.ear=1 then begin
    who_is_here;
   end;

   crlf;
   sd(config.textcolor,'Healing Hut (H,C,R,S,?) :');
  end;
 end
 else begin
  if (player.expert=false) or (force=true) then begin
   meny;
  end;
 end;
end;

Procedure Healer;
const disease_col =ulgray ; {display disease names in this color}
var
    x,
    y,
    justval : integer;

    healed, found, leave_place : boolean;

    ch : char;

    i,
    j,
    cc,
    xx,
    total,
    cursecost : longint;

    s : s70;

    cost : array [1..5] of ^longint;

    objekt : ^orec; {item record}

begin

 {init pointer vars}
 new(objekt);
 for i:=1 to 5 do begin
  new(cost[i]);
 end;

 cost[1]^:=player.level*5000;
 cost[2]^:=player.level*6000;
 cost[3]^:=player.level*7000;
 cost[4]^:=player.level*7500;
 cost[5]^:=player.level*8500;

 cursecost:=player.level*1000;

 leave_place:=false;
 crlf;
 repeat

  {update online location, if necessary}
  if onliner.location<>onloc_healer then begin
   refresh:=true;
   onliner.location :=onloc_healer;
   onliner.doing    :=location_desc(onliner.location);
   add_onliner(OUpdateLocation,onliner);
  end;

  {display menu}
  display_menu(true,true);

  {get user input}
  ch:=upcase(getchar);

  {evaluate user input}
  case ch of
   '?':begin {display menu}
        if player.expert=true then display_menu(true,false)
                              else display_menu(false,false);
       end;
   'S':begin {player status}
        status(player);
       end;
   'C':begin
        if config.classic then begin
         crlf;
         d(15,'Not available in Classic mode.');
        end
        else begin
         crlf;
         crlf;
         sd(global_talkcol,'Alright, let''s have a look at you!');
         sd(config.textcolor,', ');
         sd(global_plycol,manager);
         d(config.textcolor,' says.');

         crlf;

         found:=false;
         for y:=1 to global_maxitem do begin
          if player.item[y]>0 then begin
           load_objekt(objekt^,player.itemtype[y],player.item[y]);

           if objekt^.cursed=true then begin
            found:=true;

            sd(config.textcolor,'Your ');
            sd(global_itemcol,objekt^.name);
            d(config.textcolor,' is cursed.');

            sd(config.textcolor,'It will cost ');
            sd(14,commastr(cursecost));
            d(config.textcolor,' '+many_money(cursecost)+' to remove.');

            if confirm('Go ahead ','Y')=true then begin
             if player.gold<cursecost then begin
              You_Cant_Afford_It;
             end
             else begin
              sd(global_plycol,manager);
              sd(config.textcolor,' recites some strange spells...');

              make_delay_dots(2,4,250);

              crlf;
              d(14,'Suddenly!');
              sd(config.textcolor,'the ');
              sd(global_itemcol,objekt^.name);
              d(config.textcolor,' disintegrates!');

              crlf;
              sd(global_plycol,manager);
              d(config.textcolor,' smiles at you. You pay the old man for');
              d(config.textcolor,'his well performed service.');
              crlf;

              player.item[y]:=0;
              {pay for treatment}
              decplayermoney(player,cursecost);
             end;
            end;
           end;
          end;
         end; {for y:= .end.}

         if not found then begin
          d(global_talkcol,'Your equipment is alright!');
         end;

        end;
       end;

   'H':begin {Heal disease}

        crlf;
        crlf;
        sd(10,'"Alright, let''s have a look at you!"');
        sd(config.textcolor,', ');
        sd(global_plycol,manager);
        d(config.textcolor,' says.');

        crlf;
        y:=0;

        d(5,'Affecting Diseases');
        d(5,'------------------');
        if player.blind=true then begin
         d(4,'(B)lindness');
         inc(y);
        end;
        if player.plague=true then begin
         d(4,'(P)lague');
         inc(y);
        end;
        if player.smallpox=true then begin
         d(4,'(S)mallpox');
         inc(y);
        end;
        if player.measles=true then begin
         d(4,'(M)easles');
         inc(y);
        end;
        if player.leprosy=true then begin
         d(4,'(L)eprosy');
         inc(y);
        end;

        if y=0 then begin
         d(7,'No diseases found!');
         crlf;
         sd(global_talkcol,'You are wasting my time!');
         sd(config.textcolor,', ');
         sd(global_plycol,manager);
         d(config.textcolor,' says and returns to his desk.');
         crlf;
         pause;
        end
        else begin

         crlf;
         menu('(C)ure all, or corresponding letter');
         sd(config.textcolor,':');

         repeat

          {get user-input}
          ch:=upcase(getchar);

          if (ch='B') and (player.blind=false) then ch:=' ';
          if (ch='P') and (player.plague=false) then ch:=' ';
          if (ch='S') and (player.smallpox=false) then ch:=' ';
          if (ch='M') and (player.measles=false) then ch:=' ';
          if (ch='L') and (player.leprosy=false) then ch:=' ';

         until ch in ['C','B','P','S','M','L'];

         crlf;
         total:=0;
         healed:=false;

         {evaluate user-input}
         case ch of
          'B':begin {cure blindness}
               sd(config.textcolor,'For healing '+disease_col+'Blindness'+config.textcol1+' I want ');
               sd(14,commastr(cost[1]^));
               sd(config.textcolor,' '+many_money(cost[1]^)+', ');
               sd(global_plycol,manager);
               d(config.textcolor,' says.');
               crlf;
               if confirm('Go ahead and pay ','Y')=true then begin
                if player.gold<cost[1]^ then begin
                 crlf;
                 You_Cant_Afford_It;
                 crlf;
                 pause;
                end
                else begin
                 crlf;
                 decplayermoney(player,cost[1]^);
                 player.blind:=false;
                 healed:=true;
                end;
               end;
              end;
          'P':begin {cure plague}
               sd(config.textcolor,'For healing the '+disease_col+'Plague'+config.textcol1+' I want ');
               sd(14,commastr(cost[2]^));
               sd(config.textcolor,' '+many_money(cost[2]^)+', ');
               sd(global_plycol,manager);
               d(config.textcolor,' says.');
               crlf;
               if confirm('Go ahead and pay ','Y')=true then begin
                if player.gold<cost[2]^ then begin
                 crlf;
                 You_Cant_Afford_It;
                 crlf;
                 pause;
                end
                else begin
                 crlf;
                 decplayermoney(player,cost[2]^);
                 player.plague:=false;
                 healed:=true;
                end;
               end;
              end;
          'S':begin {cure smallpox}
               sd(config.textcolor,'For healing your '+disease_col+'Smallpox'+config.textcol1+' I want ');
               sd(14,commastr(cost[3]^));
               sd(config.textcolor,' '+many_money(cost[3]^)+', ');
               sd(global_plycol,manager);
               sd(config.textcolor,' says.');
               crlf;
               if confirm('Go ahead and pay ','Y')=true then begin
                if player.gold<cost[3]^ then begin
                 crlf;
                 You_Cant_Afford_It;
                 crlf;
                 pause;
                end
                else begin
                 crlf;
                 decplayermoney(player,cost[3]^);
                 player.smallpox:=false;
                 healed:=true;
                end;
               end;
              end;
          'M':begin {cure measles}
               sd(config.textcolor,'For healing your '+disease_col+'Measles'+config.textcol1+' I want ');
               sd(14,commastr(cost[4]^));
               sd(config.textcolor,' '+many_money(cost[4]^)+', ');
               sd(global_plycol,manager);
               d(config.textcolor,' says.');
               crlf;
               if confirm('Go ahead and pay ','Y')=true then begin
                if player.gold<cost[4]^ then begin
                 crlf;
                 You_Cant_Afford_It;
                 crlf;
                 pause;
                end
                else begin
                 crlf;
                 decplayermoney(player,cost[4]^);
                 player.measles:=false;
                 healed:=true;
                end;
               end;
              end;
          'L':begin {cure leprosy}
               sd(config.textcolor,'For healing your '+disease_col+'Leprosy'+config.textcol1+' I want ');
               sd(14,commastr(cost[5]^));
               sd(config.textcolor,' '+many_money(cost[5]^)+', ');
               sd(global_plycol,manager);
               d(config.textcolor,' says.');
               crlf;
               if confirm('Go ahead and pay ','Y')=true then begin
                if player.gold<cost[5]^ then begin
                 crlf;
                 You_Cant_Afford_It;
                 crlf;
                 pause;
                end
                else begin
                 crlf;
                 decplayermoney(player,cost[5]^);
                 player.leprosy:=false;
                 healed:=true;
                end;
               end;
              end;
          'C':begin {cure all}
               if player.blind=true then inc(total,cost[1]^);
               if player.plague=true then inc(total,cost[2]^);
               if player.smallpox=true then inc(total,cost[3]^);
               if player.measles=true then inc(total,cost[4]^);
               if player.leprosy=true then inc(total,cost[5]^);

               sd(config.textcolor,'A '+disease_col+'complete healing'+config.textcol1+' process will cost you ');
               sd(14,commastr(total));
               sd(config.textcolor,' '+many_money(total)+', ');
               sd(global_plycol,manager);
               d(config.textcolor,' says.');
               crlf;

               if confirm('Go ahead and pay ','Y')=true then begin
                if player.gold<total then begin
                 crlf;
                 You_Cant_Afford_It;
                 crlf;
                 pause;
                end
                else begin
                 decplayermoney(player,total);
                 player.blind:=false;
                 player.plague:=false;
                 player.smallpox:=false;
                 player.measles:=false;
                 player.leprosy:=false;
                 healed:=true;
                end;
               end;
              end;

         end; {case .end.}

         if healed=true then begin
          crlf;
          sd(config.textcolor,'You give ');
          sd(global_plycol,manager);
          d(config.textcolor,' the '+config.moneytype+'. He tells you to lay down on a');
          d(config.textcolor,'bed, in a room nearby.');
          sd(config.textcolor,'You soon fall asleep...');
          delay2(800);
          sd(config.textcolor,'...');
          delay2(800);
          sd(config.textcolor,'...');
          delay2(800);
          sd(config.textcolor,'...');
          delay2(800);
          sd(config.textcolor,'...');
          crlf;
          d(config.textcolor,'When you wake up from your well earned sleep, you feel');
          d(config.textcolor,'much stronger than before!');
          sd(config.textcolor,'You walk out to ');
          sd(global_plycol,manager);
          d(config.textcolor,'...');

          {news-paper}
          newsy(true,
          'Healer',
          ' '+uplc+player.name2+config.textcol1+' spent some time with '+ulmag+manager+config.textcol1+', the healer.',
          ' '+uplc+player.name2+config.textcol1+' paid to get rid of some annoying diseases...',
          '',
          '',
          '',
          '',
          '',
          '',
          '');

          crlf;
          pause;
         end;
        end;
       end;
   'R':begin {return to street}
        leave_place:=true;
        crlf;
       end;
  end; {case .end.}

 until leave_place;

 {dispose pointer vars}
 for i:=1 to 5 do begin
  dispose(cost[i]);
 end;
 dispose(objekt);

end; {Healer *end*}

end. {Unit Healerc .end.}
