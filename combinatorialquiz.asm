TITLE Combinatorial Quiz

;----------------------------------------------------------------------
; Author: Erica Bevilacqua
; Description: Program which quizzes user on combinations problems. Randomly 
;    generates set (n) and subset (r) sizes within specified limits, presents
;    the problem to the user, and asks the user to provide their answer. Calculates
;    the actual answer on the FPU using n!/(r!(n-r)!), reports the answer to the user, 
;    and indicates whether the user was correct or not. Prompts the user whether
;    they want another question (Y/N), and loops until the user quits. Total number
;    correct and incorrect answers are reported. User input for their answer is 
;    validated to ensure exclusively numeric digits are entered, and user input for Y/N
;    is validated to ensure only a single character 'Y'/'y'/'N'/'n' is entered; 
;    on invalid input user is given an error message and reprompted. 
;
;    Integer versions of 'factorial' and 'combinations' procedures are also included 
;    but have been commented out. Uncomment & comment out FPU versions to use.
;-----------------------------------------------------------------------

INCLUDE Irvine32.inc
INCLUDE Macros.inc

N_LO = 3
N_HI = 12
R_LO = 1
STR_LEN = 32

mMyWriteString MACRO strLabel
     push      edx
     mov       edx, OFFSET strLabel
     call      WriteString
     pop       edx
ENDM


.data
randN          DWORD     ?              ; randomly generated n for problem
randR          DWORD     ?              ; randomly generated r for problem
userGuess      DWORD     ?              ; user's answer to combinations problem 
result         DWORD     1              ; actual result of combinations problem
score          DWORD     0              ; user score
probCount      DWORD     0              ; problem counter
numAnsString   BYTE      STR_LEN DUP(0) ; container for user-inputted string -- user answer to prob
yesNoStr       BYTE      STR_LEN DUP(0) ; container for user-inputted string -- y/no response      
yesOrNo        DWORD     ?              ; 0/1 based on whether user requests another problem   

titleAndName   BYTE      "Combinatorial Quiz     Erica Bevilacqua",13,10,0
ecOne          BYTE      "**EC: Number each problem. Keeping score & at the end report number right/wrong.",13,10,0
ecTwo          BYTE      "**EC: Use floating point unit to calculate factorials & nCr.",13,10,0 
instructA      BYTE      "I will display a combinations problem for you to solve.",13,10,0 
instructB      BYTE      "Enter your answer, then I will display the correct solution.",13,10,0
anotherProb    BYTE      "Would you like another problem? (Y/N): ",0
invalidMess    BYTE      "Invalid response. Please try again.",13,10,0
probDispA      BYTE      "-- Problem #",0
probDispB      BYTE      "--",13,10,0
combSet        BYTE      "Number of items in the set (n): ",0
combElems      BYTE      "Number of elements to choose (r): ",0
getGuess       BYTE      "Please enter your answer: ",0
resDisplayA    BYTE      "If choosing ",0
resDisplayB    BYTE      " item(s) from a set of ",0
resDisplayC    BYTE      ", the number of possible combinations is: ",0
userAns        BYTE      "You answered: ",0
ansRight       BYTE      "You were correct!",13,10,0
ansWrong       BYTE      "Sorry, your answer was incorrect.",13,10,0
scoreRepA      BYTE      "Total correct answers: ",0
scoreRepB      BYTE      "Total incorrect answers: ",0
goodBye        BYTE      "Thank you! Goodbye!",13,10,0

.code
main PROC
; seed random num generator
     call      Randomize                

; display title, author, & instructions
     call      introduction
     call      instructions

; run quiz
another:
     push      OFFSET probCount
     push      OFFSET randR
     push      OFFSET randN
     call      showProblem
     
     push      OFFSET userGuess
     push      OFFSET numAnsString
     call      getData
     
     push      OFFSET result
     push      randR
     push      randN
     call      combinations 
     
     push      OFFSET score
     push      userGuess
     push      result
     push      randN
     push      randR
     call      showResults
     
; check if user wants another problem
     push      OFFSET yesOrNo
     push      OFFSET yesNoStr
     call      getYesOrNo
     mov       eax, yesOrNo
     mov       ebx, 1                   
     cmp       eax, ebx
     je        another

; user finished
     push      probCount
     push      score
     call      scoreReport
     
     call      farewell  

	exit                               ; exit to operating system
main ENDP


;         introduction
; Displays author name, program title, & EC completed.   
; receives: n/a (uses global strings)
; returns: n/a
; preconditions: mMyWriteString defined 
; registers changed: n/a (edx saved & restored)
introduction PROC
     push      ebp
     mov       ebp,esp
     
     mWriteSpace 20
     mMyWriteString titleAndName
     mMyWriteString ecOne
     mMyWriteString ecTwo
     call      Crlf
      
     pop       ebp
     ret
introduction ENDP



;         instructions
; Displays program instructions to user.
; receives: n/a (uses global strings)
; returns: n/a
; preconditions: mMyWriteString defined 
; registers changed: n/a (edx saved & restored)
instructions PROC
     push      ebp
     mov       ebp, esp  
     
     mMyWriteString instructA
     mMyWriteString instructB
     call      Crlf
     
     pop       ebp
     ret
instructions ENDP



;         showProblem
; Generates random integers w/in specified range for n [N_LO...N_HI] 
;    and r [1...n]. Displays combinations problem.
; receives:
;    @randN      ; address of n
;    @randR      ; address of r
;    (also uses global strings & consts)
; returns: random ints in specified ranges at @randN, @randR
; preconditions: limits - n <= 12 if using DWORDs, r <= n 
;    mMyWriteString defined
; registers changed: n/a (eax, ebx, edx saved & restored)
showProblem PROC
     n@        EQU DWORD PTR [ebp+8]
     r@        EQU DWORD PTR [ebp+12]
     count@    EQU DWORD PTR [ebp+16]

     push      ebp
     mov       ebp, esp
     push      eax
     push      ebx
     
; generate random n [N_LO...N_HI]
     mov       eax, N_HI
     sub       eax, N_LO
     inc       eax
     call      RandomRange
     add       eax, N_LO
     mov       ebx, n@
     mov       [ebx], eax               ; store generated n at @randN 
; generate random r [1...n]    
     mov       eax, n@
     mov       eax, [eax]               ; get n that was generated
     sub       eax, R_LO
     inc       eax
     call      RandomRange
     add       eax, R_LO
     mov       ebx, r@
     mov       [ebx], eax               ; store generated r at @randR
; display problem number header
     call      Crlf
     mMyWriteString probDispA
     mov       eax, count@
     mov       eax, [eax]
     inc       eax                      ; increment prob count
     call      WriteDec
     mMyWriteString probDispB
     mov       ebx, count@
     mov       [ebx], eax               ; store new count
; display problem
     mMyWriteString combSet
     mov       eax, n@
     mov       eax, [eax]
     call      WriteDec
     call      Crlf
     mMyWriteString combElems
     mov       eax, r@
     mov       eax, [eax]
     call      WriteDec
     call      Crlf
     call      Crlf   
     
     pop       ebx
     pop       eax
     pop       ebp
     ret       12
showProblem ENDP



;         getData   
; Takes user answer to problem as a string, validates string 
;    only contains digits. If so, parses into unsigned 32-bit int
;    and saves answer, if not, preprompts user.
; receives:
;    @userGuess          ; @ where user answer will be stored
;    @numAnsString       ; @ of string container for user input
;    (& uses global strings & constant)
; returns: user answer as int at @userGuess
; preconditions: mMyWriteString defined 
; registers changed: n/a (eax, ebx, ecx, edx saved & restored)
getData PROC
     numStr@  EQU DWORD PTR [ebp+8]
     guess@   EQU DWORD PTR [ebp+12]
     strLen   EQU DWORD PTR [ebp-4]

     push      ebp
     mov       ebp, esp
     sub       esp, 4
     push      eax
     push      ebx
     push      ecx
     push      edx
     
getUserGuess:
; get user input as string    
     mMyWriteString getGuess
     mov       edx, numStr@
     mov       ecx, STR_LEN - 1
     call      ReadString
     mov       strLen, eax              ; store actual length
; loop through string and check all chars are ASCII digits
     mov       ecx, strLen
     mov       edx, string@
checkForDigits:
     mov       al, [edx]
     call      IsDigit
     jnz       invalidNum               ; contains non-digits
     inc       edx                      ; get next char
     loop      checkForDigits
; all digits, so parse string into int
     mov       edx, string@
     mov       ecx, strLen
     call      ParseDecimal32
     mov       ebx, guess@
     mov       DWORD PTR [ebx], eax     ; store parsed num at @userGuess
     jmp       getDataDone
; else, string contained non-digits -- reprompt
invalidNum:
     mMyWriteString invalidMess
     jmp       getUserGuess

getDataDone:    
     pop       edx
     pop       ecx
     pop       ebx
     pop       eax
     mov       esp, ebp
     pop       ebp
     ret       8
getData ENDP



;         combinations (FPU version)
; Calculates nCr on the floating point unit using the 
;    formula n!/(r!(n-r)!). Uses subprocedure 'factorial.'
; receives:
;    randN          ; current n to use in formula
;    randR          ; current r to use in formula
;    @result        ; @ where result of calculation will be stored
;    (& uses global strings)
; returns: solution to nCr at @result
; preconditions: n & r already selected, n & r positive ints, 
;    r <= n, mMyWriteString defined
; registers changed: n/a (eax, ebx, ecx, edx saved & restored)
combinations PROC
     n              EQU DWORD PTR [ebp+8]
     r              EQU DWORD PTR [ebp+12]
     result@        EQU DWORD PTR [ebp+16]
     nFact          EQU DWORD PTR [ebp-4]
     rFact          EQU DWORD PTR [ebp-8]
     nMinusRFact    EQU DWORD PTR [ebp-12]
     nMinusR        EQU DWORD PTR [ebp-16]
     
     push      ebp
     mov       ebp,esp
     sub       esp, 16
     push      eax
     push      ebx
     push      edx
     push      edi

; if n = r, nCr = 1
     mov       eax, n
     mov       ebx, r
     cmp       eax, ebx
     jne       calculate
     mov       edi, result@
     mov       eax, 1
     mov       [edi], eax               ; store at @result
     jmp       done
; else, calculate nCr     
calculate:       
; get n!
     lea       eax, nFact
     push      eax                      ; @nFact
     push      n    
     finit    
     fild      n                        ; initialize FPU stack by pushing first val
     call      factorial
; get r!
     lea       eax, rFact
     push      eax                      ; @rFact
     push      r
     finit 
     fild      r                        ; initialize FPU stack by pushing first val
     call      factorial
; get (n - r)!
     lea       eax, nMinusRFact    
     push      eax                      ; @nMinusRFact
     mov       eax, n
     sub       eax, r
     push      eax                      ; n-r
     mov       nMinusR, eax
     finit     
     fild      nMinusR                  ; initialize stack by pushing first val
     call      factorial
; calculate n!/(r!(n-r)!)
     fild      nFact
     fild      rFact
     fild      nMinusRFact
     fmul
     fdiv
     mov       edi, result@
     fist      DWORD PTR [edi]          ; store result

done:     
     pop       edi
     pop       edx
     pop       ebx
     pop       eax
     mov       esp, ebp
     pop       ebp
     ret       12
combinations ENDP


 
;         factorial (FPU version)
; Recursively calculates n! using the float point unit. Subprocedure of
;    'combinations'.
; receives:
;    randN/randR/nMinusR        ; copy of current int for which factorial will be calculated
;    @nFact/rFact/nMinusRFact   ; @ where result of factorial will be stored  
; returns: solution to n! at passed @ (@nFact/rFact/nMinusRFact)
; preconditions: number is positive integer, FPU initialized by caller,
;    initial n pushed to FPU stack by caller 
; registers changed: n/a (eax, ebx saved & restored)
factorial PROC
     currN     EQU DWORD PTR [ebp+8]
     factRes@  EQU DWORD PTR [ebp+12]
     
     push      ebp
     mov       ebp, esp
     push      eax
     push      ebx
     
     mov       eax, currN
; check if base case
     cmp       eax, 1 
     je        done
; else, continue
recurse:
     dec       currN
     fild      currN                    
     fmul                               ; multiply curr result * n-1
     push      factRes@                 ; parameter for recursive call
     push      currN                    ; parameter for recursive call
     call      factorial
done:
     mov       eax, factRes@ 
     fist      DWORD PTR [eax]          ; store result
     
     pop       ebx
     pop       eax
     pop       ebp
     ret       8
factorial ENDP 



; ;         combinations (integer unit version)
; ; TO USE: 
; ;    set  N_LO = 3  N_HI = 12
; ;    comment out FPU versions of PROCs combinations & factorial
; ;    uncomment integer versions of PROCs combinations & factorial 
; combinations PROC
     ; n              EQU DWORD PTR [ebp+8]
     ; r              EQU DWORD PTR [ebp+12]
     ; result@        EQU DWORD PTR [ebp+16] 
     ; nFact          EQU DWORD PTR [ebp-4]
     ; rFact          EQU DWORD PTR [ebp-8]
     ; nMinusRFact    EQU DWORD PTR [ebp-12]
     
     ; push      ebp
     ; mov       ebp,esp
     ; sub       esp, 12
     ; push      eax
     ; push      edx

; ; if n = r, nCr = 1
     ; mov       eax, n
     ; mov       ebx, r
     ; cmp       eax, ebx
     ; jne       calculate
     ; mov       edi, result@
     ; mov       eax, 1
     ; mov       [edi], eax               ; store at @result
     ; jmp       done

; ; else, calculate nCr  
; calculate:
; ; get n!
     ; lea       eax, nFact
     ; push      eax                      ; @nFact
     ; push      n                        
     ; call      factorial
; ; get r!
     ; lea       eax, rFact
     ; push      eax                      ; @rFact
     ; push      r
     ; call      factorial
; ; get (n - r)!
     ; lea       eax, nMinusRFact    
     ; push      eax                      ; @nMinusRFact
     ; mov       eax, n
     ; sub       eax, r
     ; push      eax                      ; n-r
     ; call      factorial
; ; calculate n!/(r!(n-r)!)
     ; mov       eax, nMinusRFact
     ; mov       ebx, rFact
     ; mul       ebx   
     ; mov       ebx, eax                 ; r!(n-r)! is divisor
     ; mov       eax, nFact               ; n! is dividend
     ; cdq
     ; div       ebx
     ; mov       edi, result@
     ; mov       [edi], eax               ; store at @result

; done:    
     ; pop       edx
     ; pop       eax
     ; mov       esp, ebp
     ; pop       ebp
     ; ret       12
; combinations ENDP



; ;       factorial (integer unit version)
; ; TO USE: 
; ;    set  N_LO = 3  N_HI = 12
; ;    comment out FPU versions of PROCs combinations & factorial
; ;    uncomment integer versions of PROCs combinations & factorial 
; factorial PROC
     ; push      ebp
     ; mov       ebp,esp
     ; push      eax
     ; push      ebx
     ; push      edx
     ; push      edi
         
     ; mov       eax, [ebp+8]               ; n
; ; check if base case
     ; cmp       eax, 0                     ; base case?
     ; jne       recurse
     ; mov       edi, [ebp+12]              ; @ of result
     ; mov       DWORD PTR [edi], 1         ; return 1 as base case result
     ; jmp       done
; ; else continue
; recurse:
     ; push      DWORD PTR [ebp+12]         ; @ of result
     ; mov       eax, [ebp+8]
     ; dec       eax                        ; n-1
     ; push      eax
     ; call      factorial
; return:
     ; mov       edi, [ebp+12]            ; @ of prev result
     ; mov       eax, [edi]               ; val of prev result
     ; mov       ebx, [ebp+8]             ; n
     ; mul       ebx                      ; n * prev result
     ; mov       [edi], eax               ; store product as current result
; done:     
     ; pop       edi
     ; pop       edx
     ; pop       ebx
     ; pop       eax
     ; pop       ebp
     ; ret       8
; factorial ENDP



;         showResults
; Displays correct answer to combinations problem as well as user's guess.
;    Informs user whether their answer was correct or incorrect. If correct, 
;    increments user score. 
; receives:
;    randR          ; copy of current r
;    randN          ; copy of current n
;    result         ; copy of current problem answer
;    userGuess      ; copy of user guess at answer
;    @score         ; address of user score
;    (& uses global strings)
; returns: updated score at @score
; preconditions: r, n have been generated, nCr result has been calculated,
;    userGuess has been validated & stored, mMyWriteString defined 
; registers changed: n/a (eax, ebx, ecx, edx saved & restored)
showResults    PROC
     resR      EQU DWORD PTR [ebp+8]
     resN      EQU DWORD PTR [ebp+12]
     resAns    EQU DWORD PTR [ebp+16]
     resGuess  EQU DWORD PTR [ebp+20]
     score@    EQU DWORD PTR [ebp+24]

     push      ebp
     mov       ebp, esp
     push      eax
     push      ebx 

     mMyWriteString resDisplayA
     mov       eax, resR
     call      WriteDec
     mMyWriteString resDisplayB
     mov       eax, resN
     call      WriteDec 
     mMyWriteString resDisplayC
     mov       eax, resAns
     call      WriteDec
     call      Crlf
; show user guess
     mMyWriteString userAns
     mov       eax, resGuess
     call      WriteDec
     call      Crlf
; check if user guess right or wrong
     mov       eax, resAns
     mov       ebx, resGuess
     cmp       eax, ebx
     je        correct
; answer incorrect     
     mMyWriteString ansWrong
     call      Crlf
     jmp       resultDone
; answer correct
correct:
     mMyWriteString ansRight
     call      Crlf
     mov       eax, score@
     mov       eax, [eax]
     inc       eax                      ; score++
     mov       ebx, score@
     mov       [ebx], eax               ; store new score
          
resultDone:     
     pop       ebx
     pop       eax
     pop       ebp
     ret       20
showResults    ENDP



;         getYesOrNo
; Asks if user would like another problem, takes user input as a string,
;    validates user has inputted only 'Y'/'y'/'N'/'n' and returns true (1)
;    if user chooses yes, false (0) if the user chooses no. Any other input
;    will display an error message and cause the user to be reprompted. 
; receives:
;    @yesNoStr          ; @ of container for input string
;    @yesOrNo           ; @ where result will be stored
;    (& uses global strings)
; returns: true (1) for yes or false (0) for no at @yesOrNo
; preconditions: mMyWriteString defined
; registers changed: n/a (eax, ebx, ecx, edx saved & restored)
getYesOrNo PROC
     string@    EQU DWORD PTR [ebp+8]
     yOrNoAns@  EQU DWORD PTR [ebp+12]

     push      ebp
     mov       ebp, esp
     push      eax
     push      ebx
     push      ecx
     push      edx

takeInput:
     mMyWriteString anotherProb
     mov       edx, string@
     mov       ecx, STR_LEN - 1
     call      ReadString
; make sure only single char (plus null)   
     mov       ebx, 1
     cmp       eax, ebx                 ; eax contains num chars entered by user 
     ja        invalid
; check if char is Y/y/N/n
     mov       edx, string@
     mov       al, [edx]                ; get first/only char of string
     mov       bl, 'Y'
     cmp       al, bl
     je        yesAnswer
     mov       bl, 'y'
     cmp       al, bl
     je        yesAnswer
     mov       bl, 'N'
     cmp       al, bl
     je        noAnswer
     mov       bl, 'n'
     cmp       al, bl
     je        noAnswer
     jmp       invalid                  ; some char other than Y/y/N/n
; if 'y' or 'Y'
yesAnswer:
     mov       ebx, yOrNoAns@
     mov       eax, 1
     mov       [ebx], eax               ; return true (1)
     jmp       done
; if 'n' or 'N'
noAnswer:
     mov       ebx, yOrNoAns@
     mov       eax, 0
     mov       [ebx], eax               ; return false (0)
     jmp       done
; string invalid (longer than 1 char or not Y/y/N/n)
invalid :
     mMyWriteString invalidMess
     jmp  takeInput                     ; reprompt

done:
     pop       edx
     pop       ecx
     pop       ebx
     pop       eax
     pop       ebp
     ret       8
getYesOrNo ENDP



;         scoreReport
; Displays user's total number answers correct & incorrect.
; receives: 
;    score          ; copy of number correct answers by user
;    probCount      ; copy of total number of problems attempted
;    (& uses global strings)
; returns: n/a
; preconditions: score has been calculated during game play,
;    running total of problems has been kept, mMyWriteString defined
; registers changed: n/a (eax, edx saved & restored)
scoreReport PROC
     push      ebp
     mov       ebp, esp
     push      eax

     call      Crlf
     mMyWriteString scoreRepA
     mov       eax, [ebp+8]             ; num correct
     call      WriteDec
     call      Crlf
     mMyWriteString scoreRepB
     mov       eax, [ebp+12]            ; total num problems
     sub       eax, [ebp+8]             ; num incorrect = total problems - num correct
     call      WriteDec
     call      Crlf

     pop       eax
     pop       ebp
     ret  8
scoreReport ENDP



;         farewell
; Displays farewell message to user.
; receives: n/a  (uses global strings)
; returns: n/a
; preconditions: mMyWriteString defined
; registers changed: n/a (edx saved & restored)
farewell PROC
     push      ebp
     mov       ebp,esp
     call      Crlf
     mMyWriteString goodBye
     pop       ebp
     ret
farewell ENDP 
     


END main