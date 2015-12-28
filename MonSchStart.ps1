<#
.SYNOPSIS
Используется для создания задания мониторинга

.DESCRIPTION
Пользователь, от имени которого запускается задание должен обладать соответсвующими правами

.PARAMETER XAMLPath
Используется для указания пути к XAML файлу с описанием интерфейса пользователя

.EXAMPLE
PS C:\PS\> .\MonSchStart.ps1 -XAMLPath .\MainWindow.xaml

.EXAMPLE
PS C:\PS\> .\MonSchStart.ps1 -XAMLPath "c:\TESTPATH\MainWindow.xaml"
#>

[CmdletBinding()]
param (
	[Parameter( Mandatory=$false)]
	[string]$XAMLPath
	)

#Добавление форм и сборок для WPF
[xml]$Global:xmlWPF = Get-Content -Path $XAMLPath
try{
    Add-Type -AssemblyName PresentationCore,PresentationFramework,WindowsBase,system.windows.forms
} catch {
    Throw "Ошибка при загрузке сборок WPF."
}

#Создание XAML reader используя XmlNodeReader
$Global:xamGUI = [Windows.Markup.XamlReader]::Load((new-object System.Xml.XmlNodeReader $xmlWPF))

#Создание "переменных" из объектов из XAML
$xmlWPF.SelectNodes("//*[@Name]") | %{
    Set-Variable -Name ($_.Name) -Value $xamGUI.FindName($_.Name) -Scope Global
    }


#Обработчик события нажатия на кнопку "Создать задание" 
	$btnCreateSch.add_Click({
       $Global:MailUserCredentials = New-Object System.Management.Automation.PSCredential ($tBmailUserName.Text, $pBmailPasswd.SecurePassword)
              
       if($chBoxExchange.IsChecked)
       {
            $chBoxExchange.Content = "*" + $chBoxExchange.Content
            #Проверить серверы Exchange
       }
       if($chBoxADDS.IsChecked)
       {
            $chBoxADDS.Content="*" + $chBoxADDS.Content
            #Проверить контроллеры домена
       }
       if($chBoxHV.IsChecked)
       {
            $chBoxHV.Content = "*" + $chBoxHV.Content
            #Проверить хосты Hyper-V
       }
       if($chBoxFS.IsChecked)
       {
            $chBoxFS.Content = "*" + $chBoxFS.Content
            #Проверить свободное место на дисках
       }
       if($chBoxCheckEvent.IsChecked)
       {
            $chBoxCheckEvent.Content = "*" + $chBoxCheckEvent.Content
            #Проверить наличие критических событий
       }
       $SchActionArgument = '-NoProfile -WindowStyle Hidden -command "& {get-eventlog -logname Application -After ((get-date).AddDays(-1)) | Export-Csv -Path c:\TMP\applog.csv -Force -NoTypeInformation}"'
       [string]$TaskName = "MonSchedule-" + (Get-Date -Format "dd.MM.yy-hh.mm").ToString()
       $SchTrigger =  New-ScheduledTaskTrigger -Daily -At 9am
       $SchAction = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument $SchActionArgument
       Register-ScheduledTask -Action $SchAction -Trigger $SchTrigger -TaskName $TaskName -Description "Мониторинг указанных пользователем параметров серверов"
	})
    

#Отобразить GUI
$xamGUI.ShowDialog() | out-null