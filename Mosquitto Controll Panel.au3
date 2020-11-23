#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.14.5
 Author:         myName

 Script Function:
	Template AutoIt script.

#ce ----------------------------------------------------------------------------

#include <AutoItConstants.au3>

#include <ButtonConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <Array.au3>
#include <File.au3>



HotKeySet("{F5}", "HotKeyPressed")
HotKeySet("{F6}", "HotKeyPressed")
HotKeySet("{F4}", "HotKeyPressed")
HotKeySet("{F7}", "HotKeyPressed")
;HotKeySet("+!d", "HotKeyPressed") ; Shift-Alt-d





; Script Start - Add your code below here
Panel_sterowania_mosquitem()
While 1
	Sleep(100)
WEnd


Func HotKeyPressed()
	Switch @HotKeyPressed ; The last hotkey pressed.
		Case "{F5}" ; String is the {PAUSE} hotkey.
			Panel_sterowania_mosquitem()
		Case "{F4}" ; String is the {PAUSE} hotkey.
			Exit
		Case "{F6}" ;Dodawanie nowego uzytkownika
			przeladuj_konfiguracje()
		Case "{F7}" ;Dodawanie nowego uzytkownika
			wczytaj_adres_ip_port()
	EndSwitch
EndFunc   ;==>HotKeyPressed




Func Panel_sterowania_mosquitem()
	$mainparentGUI = GUICreate("Panel sterowania Mosquitto", 306, 132, 192, 124)
$Button2 = GUICtrlCreateButton("Nowy użytkownik", 8, 8, 145, 33)
$Button3 = GUICtrlCreateButton("Włącz MOSQUITTO", 160, 48, 137, 33)
$Button4 = GUICtrlCreateButton("Zabij MOSQUITTO", 160, 88, 137, 33)
$Button5 = GUICtrlCreateButton("Włącz monitor portu", 8, 48, 145, 33)
$Button6 = GUICtrlCreateButton("Resetuj konfiguracje", 160, 8, 137, 33)
$Button1 = GUICtrlCreateButton("Test Wiadomosci", 8, 88, 145, 33)
	GUISetState(@SW_SHOW)

	$childGUI = GUICreate("Nowy użytkownik", 266, 77, 218, 232)
	$cInput1 = GUICtrlCreateInput("Nazwa", 8, 8, 121, 21)
	$cInput2 = GUICtrlCreateInput("Haslo", 136, 8, 121, 21)
	$cButton1 = GUICtrlCreateButton("Dodaj!", 8, 40, 123, 25)
	$cButton2 = GUICtrlCreateButton("Anuluj", 136, 40, 121, 25)

	While 1
		$msg = GUIGetMsg(1)
		Switch $msg[1]
			Case $mainparentGUI
				Switch $msg[0]
					Case $GUI_EVENT_CLOSE
						GUIDelete($mainparentGUI)
						Exit
					Case $Button2
						GUISetState(@SW_DISABLE, $mainparentGUI)
						GUISetState(@SW_SHOW, $childGUI)
					Case $Button3
						Uruchom_mosqita()
					Case $Button4
						Zabij_mosqita()
					Case $Button6
						przeladuj_konfiguracje()
					Case $Button5
						rozpocznij_czat_MQTT()
					Case $Button1
						nadaj_test_MQTT()
				EndSwitch
			Case $childGUI
				Switch $msg[0]
					Case $GUI_EVENT_CLOSE
						;GUIDelete($childGUI)
						GUISetState(@SW_ENABLE, $mainparentGUI)
						GUISetState(@SW_HIDE, $childGUI)
					Case $cButton2
						GUISetState(@SW_ENABLE, $mainparentGUI)
						GUISetState(@SW_HIDE, $childGUI)
					Case $cButton1
						ConsoleWrite("Login: " & GUICtrlRead($cInput1) & @CRLF & "Hasło: " & GUICtrlRead($cInput2) & @CRLF)
						dodaj_uzytkownika(GUICtrlRead($cInput1), GUICtrlRead($cInput2))
				EndSwitch
		EndSwitch
	WEnd
EndFunc   ;==>Panel_sterowania_mosquitem


Func przeladuj_konfiguracje()
	#cs
	Opt("WinTitleMatchMode", 3)
	If (WinExists("C:\Windows\SYSTEM32\cmd.exe - mosquitto  -v")) Then
		WinKill("C:\Windows\SYSTEM32\cmd.exe - mosquitto  -v")
	EndIf
	Run("cmd.exe")
	Opt("WinTitleMatchMode", 1)
	WinWaitActive("[CLASS:ConsoleWindowClass]")
	Send("cd /d " & @ScriptDir)
	Send("{ENTER}")
	Send("mosquitto.exe restart")
	Send("{ENTER}")
	#ce
EndFunc   ;==>Uruchom_mosqita

Func Zabij_mosqita()
	$lista_procesow = ProcessList()
	;_ArrayDisplay($lista_procesow)
	For $i = 0 To UBound($lista_procesow) - 1
		;ConsoleWrite($lista_procesow[$i][0] & @CRLF)
		If $lista_procesow[$i][0] = "mosquitto.exe" Then
			If (ProcessClose($lista_procesow[$i][1]) == 1) Then
				MsgBox($MB_SYSTEMMODAL, "Sukces", "Udało się zamknąć mosquittos.exe ", 2)
				WinKill("C:\Windows\SYSTEM32\cmd.exe - mosquitto  -v")
				exitloop(1)
			Else
				MsgBox($MB_SYSTEMMODAL, "Porażka", "Nie można zamknąć procesu ", 2)

			EndIf

		ElseIf $i = UBound($lista_procesow) - 1 Then
			MsgBox($MB_SYSTEMMODAL, "Porażka", "Proces nie istnieje", 2)

		EndIf
	Next
	WinKill("C:\Windows\SYSTEM32\cmd.exe - mosquitto  -v")
EndFunc   ;==>Zabij_mosqita

Func dodaj_uzytkownika($login, $password)
	If FileExists(@ScriptDir & "/passwd") = 0 Then
		DirCreate(@ScriptDir & "/passwd")
		FileOpen(@ScriptDir & "/passwd/User", 8)
		FileClose(@ScriptDir & "/passwd/User")
	EndIf
	ConsoleWrite("Uruchamiam: " & @ScriptDir & "/mosquitto_passwd.exe -b " & @ScriptDir & "/passwd/User " & $login & " " & $password & @CRLF)
	Run(@ScriptDir & "/mosquitto_passwd.exe -b " & @ScriptDir & "/passwd/User " & $login & " " & $password)
	MsgBox($MB_SYSTEMMODAL, "Sukces", "Uzytkownik dodany!", 2)
EndFunc   ;==>dodaj_uzytkownika

Func Uruchom_mosqita()
	;Przywraca konfigurację w pliku mosquitto conf
	Local $lista = ["listener 8883 10.1.1.100", _
			"per_listener_settings true", _
			"protocol mqtt", _
			"password_file E:\mosqut\mosquitto\passwd\User", _
			"log_dest syslog", "log_dest stdout", "log_dest topic", _
			"log_type error", _
			"log_type warning", _
			"log_type notice", _
			"log_type information", _
			"connection_messages true", _
			"log_timestamp true", _
			"allow_anonymous false"];, _
			;"persistence true", _
			;"persistence_location E:\mosqut\mosquitto\", _
			;"persistence_file mosquitto.db"]

	_FileWriteFromArray(@ScriptDir & "/mosquitto.conf", $lista)


	ConsoleWrite("Uruchamiam: " & (@ScriptDir & "/mosquitto.exe -c " & @ScriptDir & "/mosquitto.conf" & @CRLF))
	Run(@ScriptDir & "/mosquitto.exe -c " & @ScriptDir & "/mosquitto.conf")
EndFunc   ;==>przeladuj_konfiguracje

Func wczytaj_adres_ip_port()
	;Pobiera adres IP z pliku conf wraz z Portem, nie uzyta jeszcze
	Local $tablica = FileReadToArray(@ScriptDir & "/mosquitto.conf")
	_ArrayDisplay($tablica)
	Local $ip = $tablica[0]

EndFunc   ;==>wczytaj_adres_ip_port

Func nadaj_test_MQTT()
Opt("WinTitleMatchMode", 3)
	If (WinExists("C:\Windows\SYSTEM32\cmd.exe - mosquitto  -v")) Then
		WinKill("C:\Windows\SYSTEM32\cmd.exe - mosquitto  -v")
	EndIf
	Run("cmd.exe")
	Opt("WinTitleMatchMode", 1)
	WinWaitActive("[CLASS:ConsoleWindowClass]")
	Send("cd /d " & @ScriptDir)
		Send("{ENTER}")
	Send("echo Teraz nadam wiadomość do tematu mikrokontolery/temperatury")
	Send("{ENTER}")
	Send('mosquitto_pub.exe -h 10.1.1.100 -p 8883 -t "mikrokontrolery/temperatury" -m "udalo sie wyslac cokolwiek" -u test -P test -d')
	Send("{ENTER}")

EndFunc

Func rozpocznij_czat_MQTT()
Opt("WinTitleMatchMode", 3)
	If (WinExists("C:\Windows\SYSTEM32\cmd.exe - mosquitto  -v")) Then
		WinKill("C:\Windows\SYSTEM32\cmd.exe - mosquitto  -v")
	EndIf
	Run("cmd.exe")
	Opt("WinTitleMatchMode", 1)
	WinWaitActive("[CLASS:ConsoleWindowClass]")
	Send("cd /d " & @ScriptDir)
	Send("{ENTER}")
	Send("echo Teraz będę nasłuchiwał wszystkich którzy podłączą się do kanału mikrokontrolery/temrperatury")
	Send("{ENTER}")
	ConsoleWrite( @ScriptDir&'\mosquitto_sub.exe -h 10.1.1.100 -p 8883 -v -t "mikrokontrolery/#" -u login -P password -d')
	Send('mosquitto_sub.exe -h 10.1.1.100 -p 8883 -v -t "mikrokontrolery/')
	send('{#}"')
	send(" -u login -P password -d")
	Send("{ENTER}")

EndFunc