    nomainwin
    WindowWidth = 630
    WindowHeight = 720
    UpperLeftX=int((DisplayWidth-WindowWidth)/2)
    UpperLeftY=int((DisplayHeight-WindowHeight)/2)

    BackgroundColor$ = "lightgray"

    '-----Begin GUI objects code

    graphicbox #main.gbMM,   5, 165, 610, 310
    TexteditorColor$ = "white"
    texteditor #main.textedit16,   5, 505, 610, 150
    groupbox #main.gpbxReg, "Registers",   5,  15, 610,  80
    TextboxColor$ = "white"
    textbox #main.regA,  15,  60, 100,  25
    statictext #main.statictext2, "A Register",  15,  40,  63,  20
    textbox #main.regD, 360,  60, 100,  25
    statictext #main.statictext4, "D Register", 360,  40,  64,  20
    graphicbox #main.gbInput, 435,  40,  55,  18
    textbox #main.regIP, 130,  60, 100,  25
    statictext #main.statictext6, "IP Register", 130,  40,  66,  20
    textbox #main.regMAR, 245,  60, 100,  25
    statictext #main.statictext8, "MAR Register", 245,  40,  84,  20
    button #main.btnRun,"Run",[btnRunClick], UL,  85, 105,  75,  25
    button #main.btnStep,"Step",[btnStepClick], UL,   5, 105,  70,  25
    statictext #main.statictext13, "Main Memory",   5, 145,  81,  20
    button #main.btnStore,"Store",[btnStoreClick], UL, 470,  60,  60,  25
    statictext #main.statictext17, "Program Output",   5, 485,  200,  20
    statictext #main.statictext18, "Clock Speed(sec) => ", 435, 112, 125,  20
    textbox #main.tbClock, 565, 105, 45,  25

    '-----End GUI objects code

    '-----Begin menu code

    menu #main, "File",_
                "Save memory", [savemem],_
                "Load memory", [loadmem], "Exit", [quit.main]

    menu #main, "Run", "&Step", [btnStepClick], "Run", [btnRunClick] , "Stop", [terminateProgram] ' <-- this menu has no items!

    menu #main, "Edit"  ' <-- Texteditor menu.
    menu #main, "Help", "Op Codes", [showInstructions], "ASCII Codes", [showAscii], "About", [showAbout]


    '-----End menu code

    open "Decimal Machine Oriented Language" for window_nf as #main


    print #main.gbMM, "down; fill white; flush"
    print #main, "font ms_sans_serif 10"
    print #main.regA, "000"
    print #main.regD, "000"


    print #main.gbInput, "font ms_sans_serif 10"
    print #main.gbInput, "fill red"
    print #main.gbInput, "backcolor red"
    print #main.gbInput, "color white"
    print #main.gbInput, "place 5 13"
    print #main.gbInput, "|INPUT"
    print #main.gbInput, "flush"
    print #main.regIP, "01"
    print #main.regMAR, "01"
    print #main.textedit16, "!font courier_new 10"
    print #main.tbClock, "1"

    print #main, "trapclose [quit.main]"

    '----Begin code for tooltips

    'Struct for version info,
   ' struct winOSver,_
    'dwOSVersionInfoSize as long,_
    'dwMajorVersion as long,_
    'dwMinorVersion as long,_
    'dwBuildNumber as long,_
    'dwPlatformId as long,_
    'szCSDVersion as char[128]

    'get the size (len) of the struct to input to the call
   ' winOSver.dwOSVersionInfoSize.struct=len(winOSver.struct)

    'do the call to fill the struct
    'calldll #kernel32,"GetVersionExA",_
    'winOSver as struct,_
    'result as void
    'check the operating system version for enabling tooltips
    'if winOSver.dwPlatformId.struct <> 1 Then VERSION.FLAG = 1

   ' hParent = hwnd(#main)
   ' hTip=CreateTooltip(hParent)

    '----Add tooltips for controls

   ' if VERSION.FLAG = 0 then
   '     Call AddToolTip Hwnd(#main.regIP) , hTip , "Instruction Pointer"
   ' end if

    '----End tooltip code

global false
global true
global proceed
global programExecuting
global IP

false = 0
true = 1

proceed = false
programExecuting = false
stepping = true
IP = 1
printMode$ = "NUMBERS"


    call initMemory
call RenderMainMemory

[main.inputLoop]   'wait here for input event
    wait



[btnRunClick]   'Perform action for the button named 'btnRun'
   'notice "Run Clicked"
   if programExecuting = false then
     programExecuting = true
     stepping = false
     timer 100, [setupRun]
   end if
 wait

[btnStepClick]
   'notice "Step Clicked"
   if programExecuting = false then
     programExecuting = true
     stepping = true
     timer 100, [setupRun]
   else
     proceed = true
     goto [nextStep]
   end if

 wait

[btnStoreClick]   'Perform action for the button named 'btnStore'
    'notice "Button Store Clicked."
    if inputReq = false then
      txtMAR$ = "000"
      txtData$ = "000"
      'Get address from the MAR register
      print #main.regMAR, "!contents? txtMAR$";
      'Get code from the data register.
      print #main.regD, "!contents? txtData$";
      i$ = txtData$
      gosub [validateInstruction]
      txtData$ = i$
      'Insert into array.
      addr = val( txtMAR$)
      x$( addr ) = txtData$
      addr = addr + 1
      print #main.regMAR, str$(addr);
      print #main.regD, ""
      print #main.regD, "!setfocus"
      'Refresh memory
      call RenderMainMemory
    end if
    'If awaiting input, go to branch label
    if inputReq = true then
      inputReq = false
      goto [dataEntered]
    end if

    wait


[savemem]
filedialog "Save As...", "*.dml", fileName$
if fileName$ <> "" then
  open fileName$ for output as #fileOut
  for idx = 1 to 99
    print #fileOut, x$(idx)
  next idx
  close #fileOut
  notice "Memory Saved."
end if
wait


[loadmem]
filedialog "Open text file", "*.dml", fileName$
if fileName$ <> "" then
  open fileName$ for input as #fileIn
  for idx = 1 to 99
    input #fileIn, value$
    x$(idx) = value$
  next idx
  close #fileIn
  call RenderMainMemory
  notice "Memory Retrieved."
end if
wait


    wait

[quit.main] 'End the program

    a= ReleaseTooltipMemory(hTip)
    close #main
    end


'------------------------------------------------------
'----------------- Subs and Functions -----------------
'------------------------------------------------------


'FUNCTION CreateTooltip(hMain)
'    Struct TOOLINFO, _
'    cbSize As long, _
'    uFlags As long, _
'    hwnd As long, _
 '   uId As long, _
 '   rectLeft As long, _
 '   rectTop As long, _
 '   rectRight As long, _
 '   rectBottom As long, _
 '   hinst As long, _
 '   lpszText As ptr
 '
 '   CallDLL #comctl32,"InitCommonControlsEx", _
 '   ret As void
 '
 '   TOOLINFO.cbSize.struct = Len(TOOLINFO.struct)
 '   TOOLINFO.uFlags.struct = flags Or 17 'TTF_IDISHWND Or TTF_SUBCLASS
 '   TOOLINFO.hwnd.struct = hMain
 '
 '   CallDLL #user32,"CreateWindowExA",_
 '   0 As long, _
 '   "tooltips_class32" As ptr, _
 '   0 As long, style As long, _
 '   _CW_USEDEFAULT As long, _
 '   _CW_USEDEFAULT As long, _
 '   _CW_USEDEFAULT As long, _
 '   _CW_USEDEFAULT As long, _
 '   hMain As long, _
 '   0 As long, _
 '   0 as long, _
  ''  0 As long, _
  '  CreateTooltip As Long
'END FUNCTION


'SUB AddToolTip cHndl, hWnd, Text$
'
'    TOOLINFO.uId.struct = cHndl
'    TOOLINFO.lpszText.struct = Text$
'
'    CallDLL #user32, "SendMessageA",_
'    hWnd As long, _
'    1028 As long, _
 '   0 As long, _
''    TOOLINFO as ptr, _
 '   ret As long
'END SUB


'FUNCTION ReleaseTooltipMemory(hTip)
'    CallDLL #user32, "SendMessageA",_
'    hTip As long, _
'    _WM_DESTROY  As long, _
 '   w As long, _
 '   l As long, _
 '   re As long
'END FUNCTION


'------------------------------------------------------
'--------------- End Subs and Functions ---------------
'------------------------------------------------------















'This is the DEMOL simulator
'Vaariables
'a$ Accumulator value
'x$() Cell values
'i$ 3 place data of DEMOL instruction
'q$ Y or N flag
'b address of first or beginning cell
'r address of last or run cell
'dim x$(99) allocates the 99 storage location cells
'x$(i) contains the information associated the the i'th cell.
'All 99 cells and the accumulator are initialized to 000

sub initMemory
DIM x$(99)
a$ = "000"
for i = 1 to 99
x$(i) = "000"
next i
end sub


'print "Do you want the DEMOL instructions explained (y/n) ";
'input q$
'if q$ = "y" then gosub [showInstructions]
'print

'[programEntryPoint]
'print "Addressable memory must be in the 1-99 range."
'print "At what address would you like the program to begin";


'input b
'b=int(b)
'if b > 0 and b < 100 then [programEntry]
'goto [programEntryPoint]
'[programEntry]
'print
'for i = b to 99
'  print i;
'  input i$
'  if i$ = "RUN" then exit for
'  gosub [validateInstruction]
'  x$(i) = mid$(i$, 1, 3)
'next i


'Before the DEMOL program is executed, the cell containing
'the 'RUN' command is changed to 000 and the location of
'that cell is stored in R.
[setupRun]
'x$(i) = "000"
'r=i
timer 0
for t = 99 to 1 step -1
   if x$(t) <> "000" then
     r = t + 1
     exit for
   end if
next t

'The instruction pointer has the start address
startAddress$ = "000"
print #main.regIP, "!contents? startAddress$";
b = val( startAddress$ )

'notice "starting at " ; b
'notice "ending at "; r


'The following loop executes the program starting at cell b
'(location of 1st input value) to cell r (location of the 'run' statement).
'If the program jumps out of the B to R boundary via a
'branch command it will cause an addressing exception error.
'The program then and dumps
'The val function determines which operation code to perform.
'The variable a represents the address or cell location coresponding to that op-code.
[beginRun]
print #main.textedit16, ""
print #main.textedit16, "<<<<< DEMOL Program Execution >>>>>"
print #main.textedit16, ""


i = b
IP = i
[forNextLoop]
'Update the intruction pointer
print #main.regIP, str$(i)
'Update the accumulator
print #main.regA, a$
'Update memory address register
print #main.regMAR, str$(a)
IP = i
[continueInstruction]
 call RenderMainMemory

if stepping = true then wait
[nextStep]

' if running then delay
if programExecuting = true and stepping = false then
'Delay by clock speed
cs$ = "1000"
print #main.tbClock, "!contents? cs$"
cs = val(cs$)
cs = cs * 1000
now = time$("ms")
  while time$("ms") < now + cs
    scan
  wend
end if

proceed = false

'print "i:"; i
'print "x$(i):"; x$(i)
a = val( mid$(x$(i), 2 , 2))


'print "a:"; a
'A negative op-code bombs
if mid$(x$(i), 1, 1) <> "-" then [getOpCode]
print #main.textedit16, "Invaled op-code error at address:";i
goto [exitWithError]

' Get the operation code
[getOpCode] ' 1180
opCode = val( mid$(x$(i), 1, 1) ) + 1

select case opCode

   case 1
      gosub [opCodeZero]
   case 2
     if printMode$ = "NUMBERS" then
       print #main.textedit16, x$(a)
     else
       xVal = val(x$(a))
       if xVal > 0 and xVal < 256 then
         print #main.textedit16, chr$(xVal);
       else
         print #main.textedit16, xVal
       end if
     end if
     goto [nextInstruction]
   case 3
     'print #main.gbInput, "show"
     print #main.regD, ""
     print #main.regD, "!setfocus"
     inputReq = true
     wait
     [dataEntered]
     'print #main.gbInput, "hide"
     print #main.regD, "!contents? i$"

     'input i$
     gosub [validateInstruction]
     x$(a) = i$
     goto [nextInstruction]
   case 4
     a$ = x$(a)
     goto [nextInstruction]
   case 5
     x$(a) = a$
     goto [nextInstruction]
   '*** Op-Code 5, branch ***
   case 6
     if a >= b and a <= r then
       i = a : goto [continueInstruction]
     else
       'notice "Access"
       print #main.textedit16, "Addressing Exception Error at Address:";i
       goto [exitWithError]
     end if
   case 7
     if val(a$) >= 0 then [nextInstruction]
     i = a
     goto [continueInstruction]
   case 8 'Op-Code 7, add to accumulator.
     a$ = str$( val(a$) + val(x$(a)) )
     if len(a$) <= 3 then [nextInstruction]
     print #main.textedit16, "Accumulator overflow error at address"; i
     goto [exitWithError]
   case 9 'Op-Code 8, subtract from the accumulator.
     a$ = str$(val(a$) - val(x$(a)))
     if len(a$) <= 3 then [nextInstruction]
     print #main.textedit16, "Accumulator overflow error at address"; i
     goto [exitWithError]
   case 10 'Op-Code 9, branch when accumulator value is zero.
     if val(a$) <> 0 then [nextInstruction]
     i = a
     goto [continueInstruction]
  end select


[nextInstruction]
if i < r then i = i + 1
if i <= r then goto [forNextLoop]
'next i
' Run complete
'goto [changeProgram]

[terminateProgram]
print #main.textedit16, "Program terminated."
programExecuting = false
notice "Program terminated."
wait
'end

'The op-code is 0 stop and dump?
[opCodeZero]
if a = 1 then
  'Clear output
  print #main.textedit16, "!cls"
end if
if a = 2 then
  'print decimal
  printMode$ = "NUMBERS"
end if
if a = 3 then
  'print ascii
  printMode$ = "ASCII"
end if
if a = 0 then
  goto [terminateProgram]
end if

'if a = 0 then gosub [dumpMemory]
return

[exitWithError]
programExecuting = false
wait

[changeProgram]
'print
'print "Would you like to make changes and re-execute (y/n) ";
'input q$
'if q$ = "n" then goto [terminateProgram]
'This module allows changes to be made to the DEMOL program
'after it has been run. The cells before b and after r as
'well as the accumulator are initialized to 000.
'a$ = "000"
'for i = 1 to b - 1
'  x$(i) = "000"
'next i
'for i = r to 99
'  x$(i) = "000"
'next i
'This flag value supresses the directions once the change routine has been used.
'[changeInstructions]
'f = f + 1
'if f < 2 then
'  print " To make changes you must type 5 characters (no spaces)."
'  print "The number of the cell being changed goes in te first"
'  print "two places. An asterisk (*) is next, followed by the "
'  print "new 3-place data value or instruction."
'end if
'print "To re-execute the DEMOL program, simply type 00*RUN."

'[getInput]
'input c$
'if len(c$) < 6 then
'  f = 0
'  goto [changeInstructions]
'end if

'i = val(mid$(c$, 1,2))
'if i = 0 then [beginRun]
'if i < 1 or i > 99 then
'  print "The cells are numbered from 1 to 99."
'  goto [getInput]
'end if

'if b > i then b = i
'if r < i then r = i
''The gosub verifies the input
'i$ = mid$(c$, 4, 3)
'gosub [validateInstruction]
'x$(i) = mid$(i$, 1, 3)
'print "Address"; i; "has been changed to "; x$(i)
'goto [getInput]


'This is the subprogram that prints the dump.
[dumpMemory]
print
print "Dump of cells at addresses 1-99."
print
for k=1 to 99
  print using(">####", val(x$(k)));
  if int(k/10) = k/10 then print
next k
print "   Accumulator=";a$
return



[showInstructions]
print #main.textedit16, "!cls"
print #main.textedit16, "***   D E M O L   O P - C O D E S    ***"
print #main.textedit16, ""
print #main.textedit16, "1XX.......PRINT THE CONTENTS OF CELL XX."
print #main.textedit16, "2XX.......READ INPUT DATA INTO CELL XX."
print #main.textedit16, "3XX.......LOAD THE CONTENTS OF CELL XX INTO THE"
print #main.textedit16, "          ACCUMULATOR, DESTROYING ANY PREVIOUS CONTENTS."
print #main.textedit16, "4XX.......STORE A COPY OF THE ACCUMULATOR VALUE INTO CELL XX."
print #main.textedit16, "5XX.......BRANCH OR JUMP TO CELL XX FOR THE NEXT INSTRUCTION."
print #main.textedit16, "6XX.......IF THE ACCUMULATOR VALUE IS NEGATIVE, BRANCH OR"
print #main.textedit16, "          JUMP TO CELL XX FOR THE NEXT INSTRUCTION."
print #main.textedit16, "7XX.......ADD THE CONTENTS OF CELL XX TO THE CURRENT"
print #main.textedit16, "          ACCUMULATOR VALUE."
print #main.textedit16, "8XX.......SUBTRACT THE CONTENTS OF CELL XX FROM THE CURRENT"
print #main.textedit16, "          ACCUMULATOR VALUE."
print #main.textedit16, "9XX.......IF THE ACCUMULATOR VALUE IS ZERO. BRANCH OR JUMP"
print #main.textedit16, "          TO CELL XX FOR THE NEXT INSTRUCTION."
print #main.textedit16, "0XX.......NO-OP CODE. OPPERAND INDICATES SPECIAL OPERATIONS."
print #main.textedit16, "          SEE BELOW..."
print #main.textedit16, "000.......STOP EXECUTION."
print #main.textedit16, "001.......CLEAR OUTPUT WINDOW."
print #main.textedit16, "002.......SET OUTPUT TO PRINT DECIMAL NUMBER VALUES."
print #main.textedit16, "003.......SET OUTPUT TO PRINT ASCII CHARACTERS."
wait
'return
[showAscii]
print #main.textedit16, "!cls"
entry$ = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^&*()_[]\{}|;':,./<>?" + CHR$(34)
for index = 1 to len(entry$)
  result$ = result$ +mid$(entry$,index,1) +" -- " + str$(asc(mid$(entry$,index,1))) + chr$(13)
next index
#main.textedit16, result$
wait

[showAbout]
print #main.textedit16, "!cls"
print #main.textedit16, "Decimal Machine Oriented Language DEMOL"
print #main.textedit16, "Educational Simulator"
print #main.textedit16, "Based on the book 'Conversational Basic' this program is used to demonstrate"
print #main.textedit16, "how a computer processes instructions and accesses memory using operation"
print #main.textedit16, "codes and operands."
print #main.textedit16, "This program is written in JustBasic and Liberty Basic."
print #main.textedit16, "Mr. Forrett, St. Mary's Computer Lab, Worcester MA. 2016."


wait

'This is the subporgram that verifies tehe 3-place
'input value as a valid DEMOL instrucion.
[validateInstruction]
'Is it too enough?
valid = 1
if len(i$) = 0 or len(i$) > 3 then
  valid = 0
end if
'Is it a number?
if valid = 1 then
  n$ = "0123456789"
  if mid$(i$, 1,1) = "-" then  z9 = 2 else z9 = 1
  for c = z9 to len(i$)
    thisChar$ = mid$(i$, c, 1)
    pos = instr(n$, thisChar$)
    if pos = 0 then
      valid = 0
      exit for
    end if
  next c
end if
' If it is too long, or not a number then...
if valid = 0 then
prompt "Invalid Input." + chr$(13) + "Enter a number from -99 to 999"; i$
'input i$
goto [validateInstruction]
end if
t$ = ""
' Add any leading zeroes
 if z9 = 2 then
   t$ = mid$(i$, z9, 2)
   t$ = right$("00" + t$, 2)
   i$ = "-" + t$
 else
   i$ = right$("000" + i$, 3)
 end if
return

end

SUB RenderMainMemory
    startLocLeft = 3
    startLocTop = 3
    colCount = 10
    rowCount = 10
    cellWidth = 60
    cellHeight = 30
    colHeight = cellHeight * rowCount + startLocTop
    rowWidth = cellWidth * colCount + startLocLeft
    x = startLocLeft
    '11 lines, 10 cells

    for cnt = 1 to colCount + 1
        print #main.gbMM, "line ";x;" ";startLocTop;" ";x;" ";colHeight
        x = x + cellWidth
    next cnt

'row lines stepped at 20
    y=startLocTop
    for x= 1 to rowCount + 1
        print #main.gbMM, "line ";startLocLeft;" ";y;" ";rowWidth;" ";y
        y= y + cellHeight
    next x

    'Print cell location values
    print #main.gbMM, "font ms_sans_serif 8"
    print #main.gbMM, "color lightgray"

    cellVal = 1
    for ycnt = 1 to rowCount
      for xcnt = 1 to colCount
          print #main.gbMM, "place ";xcnt * cellWidth - (cellWidth - 5); " "; ycnt * cellHeight - (cellHeight - 15)
          print #main.gbMM, "|";cellVal
          cellVal = cellVal + 1
       next xcnt
     next ycnt


    'Print Main Memory values
    print #main.gbMM, "font ms_sans_serif 10"
    print #main.gbMM, "color black"

    cellVal = 1
    for ycnt = 1 to rowCount
      for xcnt = 1 to colCount
          print #main.gbMM, "place ";xcnt * cellWidth - (cellWidth - 30); " "; ycnt * cellHeight - (cellHeight - 28)
          if cellVal < 100 then
            if cellVal = IP then
              print #main.gbMM, "color red"
            else
              print #main.gbMM, "color black"
            end if
            print #main.gbMM, "|"; x$(cellVal)
          end if
          cellVal = cellVal + 1
       next xcnt
     next ycnt

    print #main.gbMM, "flush"
END SUB

