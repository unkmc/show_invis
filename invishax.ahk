#SingleInstance Force

; Pull in the NexusTK class + memory logic
#Include NexusTK.ahk

; Use a global handle so other functions could see it if needed
global MEMORY_HANDLE

; Create a NexusTK instance, which sets up this.nexusMemory, baseAddress, windowHandle, etc.
MEMORY_HANDLE := new NexusTK()  ; default "ahk_exe NexusTK.exe" is used inside __new()

; Simple infinite loop
Loop
{
    MEMORY_HANDLE.compileMonsterInfo()
    Sleep, 100   ; 1 second
}
