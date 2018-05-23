<#
    .NOTES
    --------------------------------------------------------------------------------
     Code generated by:  SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.2.124
     Generated on:       6/21/2016 3:15 PM
     Generated by:       SAPIEN Techinologies, Inc.
    --------------------------------------------------------------------------------
    .DESCRIPTION
		This GUI script generates the module preset cache files for PowerShell Studio 
		and PrimalScript
#>

#----------------------------------------------
# Generated Form Function
#----------------------------------------------
function Call-Build_Module_Cache_psf {

	#----------------------------------------------
	#region Import the Assemblies
	#----------------------------------------------
	[void][reflection.assembly]::Load('System.Windows.Forms, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089')
	[void][reflection.assembly]::Load('System.Data, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089')
	[void][reflection.assembly]::Load('System.Drawing, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a')
	#endregion Import Assemblies

	#----------------------------------------------
	#region Generated Form Objects
	#----------------------------------------------
	[System.Windows.Forms.Application]::EnableVisualStyles()
	$formBuildModuleCache = New-Object 'System.Windows.Forms.Form'
	$textboxStatus = New-Object 'System.Windows.Forms.TextBox'
	$buttonBuild = New-Object 'System.Windows.Forms.Button'
	$buttonBrowse = New-Object 'System.Windows.Forms.Button'
	$buttonCancel = New-Object 'System.Windows.Forms.Button'
	$labelModules = New-Object 'System.Windows.Forms.Label'
	$checkedlistboxModules = New-Object 'System.Windows.Forms.CheckedListBox'
	$timerJobTracker = New-Object 'System.Windows.Forms.Timer'
	$openfiledialog1 = New-Object 'System.Windows.Forms.OpenFileDialog'
	$imagelistButtonBusyAnimation = New-Object 'System.Windows.Forms.ImageList'
	$InitialFormWindowState = New-Object 'System.Windows.Forms.FormWindowState'
	#endregion Generated Form Objects

	#----------------------------------------------
	# User Generated Script
	#----------------------------------------------
	$FormEvent_Load = {
		
		$PSModuleAutoloadingPreference = 'None'
	    #Set a Default Folder
	    
	    
		$buttonBuild.Enabled = $false
		#Get all the snapins
		
		
		$formBuildModuleCache.Cursor = 'WaitCursor'
		
		Add-JobTracker -Name 'ModuleJob' -JobScript {
			$items = New-Object System.Collections.ArrayList
			$snapins = Get-PSSnapin -Registered | Select-Object -ExpandProperty Name
			foreach ($snapin in $snapins)
			{
				$members = @{
					'Name' = $snapin;
					'IsSnapin' = $true
				}
				
				[void]$items.Add((New-Object System.Management.Automation.PSObject -Property $members))
			}
			
			$modules = Get-Module -ListAvailable | Select-Object -ExpandProperty Name
			foreach ($module in $modules)
			{
				$members = @{
					'Name' = $module;
					'IsSnapin' = $false
				}
				
				[void]$items.Add((New-Object System.Management.Automation.PSObject -Property $members))
			}
			
			return $items
		} -CompletedScript {
			param ($job)
			
			$items = Receive-Job $job
			
			if ($items.Count -gt 0)
			{
				Load-ListBox -ListBox $checkedlistboxModules -Items $items -DisplayMember Name
			}
			
			$formBuildModuleCache.Cursor = 'Default'
		}
	}
	
	#region Control Helper Functions
	function Load-ListBox 
	{
	<#
		.SYNOPSIS
			This functions helps you load items into a ListBox or CheckedListBox.
	
		.DESCRIPTION
			Use this function to dynamically load items into the ListBox control.
	
		.PARAMETER  ListBox
			The ListBox control you want to add items to.
	
		.PARAMETER  Items
			The object or objects you wish to load into the ListBox's Items collection.
	
		.PARAMETER  DisplayMember
			Indicates the property to display for the items in this control.
		
		.PARAMETER  Append
			Adds the item(s) to the ListBox without clearing the Items collection.
		
		.EXAMPLE
			Load-ListBox $ListBox1 "Red", "White", "Blue"
		
		.EXAMPLE
			Load-ListBox $listBox1 "Red" -Append
			Load-ListBox $listBox1 "White" -Append
			Load-ListBox $listBox1 "Blue" -Append
		
		.EXAMPLE
			Load-ListBox $listBox1 (Get-Process) "ProcessName"
	#>
		Param (
			[ValidateNotNull()]
			[Parameter(Mandatory=$true)]
			[System.Windows.Forms.ListBox]$ListBox,
			[ValidateNotNull()]
			[Parameter(Mandatory=$true)]
			$Items,
		    [Parameter(Mandatory=$false)]
			[string]$DisplayMember,
			[switch]$Append
		)
		
		if(-not $Append)
		{
			$listBox.Items.Clear()	
		}
		
		if($Items -is [System.Windows.Forms.ListBox+ObjectCollection] -or $Items -is [System.Collections.ICollection])
		{
			$listBox.Items.AddRange($Items)
		}
		elseif ($Items -is [System.Collections.IEnumerable])
		{
			$listBox.BeginUpdate()
			foreach($obj in $Items)
			{
				$listBox.Items.Add($obj)
			}
			$listBox.EndUpdate()
		}
		else
		{
			$listBox.Items.Add($Items)	
		}
	
		$listBox.DisplayMember = $DisplayMember	
	}
	#endregion
	
	
	$checkedlistboxModules_ItemCheck=[System.Windows.Forms.ItemCheckEventHandler]{
	    #Event Argument: $_ = [System.Windows.Forms.ItemCheckEventArgs]
	    if ($_.NewValue -eq 'Checked')
	    {
	        $buttonBuild.Enabled = $true
	    }
	    else #if ($_.NewValue -eq 'Unchecked')
	    {
	        $buttonBuild.Enabled = $checkedlistboxModules.CheckedItems.Count -gt 1
	    }
	}
	
	$buttonBuild_Click={
	
	    if ($checkedlistboxModules.CheckedItems.Count -gt 0)
	    {
			Export-ModuleSelection $checkedlistboxModules.CheckedItems
		}
		
	}
	
	<#
		.SYNOPSIS
			Exports the Module cache.
	
		.DESCRIPTION
			Exports the Module cache.
	
		.PARAMETER  ModuleSelection
			PSObject containing the module / Snapin info. 
			Members:
			 	Name
				IsSnapin
	#>
	function Export-ModuleSelection
	{
		param ([ValidateNotNull()]
			$ModuleSelection)
		
		$buttonBuild.Enabled = $false
		$buttonBrowse.Enabled = $false
		$formBuildModuleCache.Cursor = 'WaitCursor'
		$textboxStatus.Text = ">> Building Cache...`r`n";
		
		#$Modules = $checkedlistboxModules.CheckedItems
		
		$commandAppData = [System.Environment]::GetFolderPath('CommonApplicationData')
		$folders = @(
		[System.IO.Path]::Combine($commandAppData, 'SAPIEN\PresetCache 2016\ModuleCacheV2'),
		[System.IO.Path]::Combine($commandAppData, 'SAPIEN\PresetCache 2016\ModuleCacheV3'),
		[System.IO.Path]::Combine($commandAppData, 'SAPIEN\PresetCache 2016\ModuleCacheV5')
		)
		
		foreach ($folder in $Folders)
		{
			try
			{
				if (-not [System.IO.Directory]::Exists($folder))
				{
					[System.IO.Directory]::CreateDirectory($folder)
				}
			}
			catch
			{
				$textboxStatus.AppendText("Unable to create folder: " + $_.Exception.Message)
				return
			}
		}
		
		foreach ($select in $ModuleSelection)
		{
			$textboxStatus.AppendText("$($select.Name)`r`n")	
		}
	
	#======================================================
		
		Add-JobTracker -Name "JobName" `
					   -JobScript {
			
			Param ($ModuleSelection,
				$Folders) #Pass any arguments using the ArgumentList parameter
			
			#region Caching Functions
			
	<#
		.SYNOPSIS
			Creates the cache files for the Module object
		
		.DESCRIPTION
			A detailed description of the Build-ModuleCache function.
		
		.PARAMETER Module
			The module or pssnapin object
		
		.PARAMETER Folders
			List of folders to save the cache to
	
	#>
			function Build-ModuleCache
			{
				
				param (
					[ValidateNotNull()]
					$Module,
					[ValidateNotNull()]
					[string[]]$Folders)
				
				
				$ModuleName = $Module.Name
				$folder = $folders[0]
				$BaseFileName = "$ModuleName." + $Module.Version.ToString()
				$CmdletFileName = $BaseFileName + '.cmdlets'
				$SyntaxFileName = $BaseFileName + '.syntax'
				$AliasFileName = $BaseFileName + '.alias'
				
				$SourceCmdletFilePath = [System.IO.Path]::Combine($folder, $CmdletFileName)
				$SourceSyntaxFilePath = [System.IO.Path]::Combine($Folder, $SyntaxFileName)
				$SourceAliasFilePath = [System.IO.Path]::Combine($Folder, $AliasFileName)
				try
				{
					
					$cmdlets = Get-Command -Module $Module.Name
					
					if ($cmdlets -ne $null)
					{
						try
						{
							if ([System.IO.Directory]::Exists($Folder) -eq $false)
							{
								[void][System.IO.Directory]::CreateDirectory($Folder)
							}
							
							$filewriter = New-Object System.IO.StreamWriter -ArgumentList ($SourceCmdletFilePath, $false, [System.Text.Encoding]::UTF8)
							$syntaxFilewriter = New-Object System.IO.StreamWriter -ArgumentList ($SourceSyntaxFilePath, $false, [System.Text.Encoding]::UTF8)
						}
						catch
						{
							Write-Error $_.Exception.Message
							return
						}
						
						$AliasStringBuilder = New-Object System.Text.StringBuilder
						foreach ($cmdlet in $cmdlets)
						{
							$command = $cmdlet -as [System.Management.Automation.CommandInfo]
							if ($command -ne $null)
							{
								if ($command.CommandType -ne 'Application' -and $command.CommandType -ne 'Alias')
								{
									Save-Command $filewriter $syntaxFilewriter $ModuleName 'P' $command
								}
								elseif ($command.CommandType -eq 'Alias')
								{
									[void]$AliasStringBuilder.AppendLine($command.Name + ' ' + $command.Definition)
								}
							}
						}
						
						$filewriter.Close()
						$syntaxFilewriter.Close()
						
						Write-File -Path $SourceAliasFilePath -Value $AliasStringBuilder.ToString()
						
						#Copy the files to the other folders
						
						for ($i = 1; $i -lt $Folders.Length; $i++)
						{
							$folder = $Folders[$i]
							
							if ([System.IO.Directory]::Exists($folder) -eq $false)
							{
								[void][System.IO.Directory]::CreateDirectory($folder)
							}
							
							[System.IO.File]::Copy($SourceCmdletFilePath, [System.IO.Path]::Combine($folder, $CmdletFileName), $true)
							[System.IO.File]::Copy($SourceSyntaxFilePath, [System.IO.Path]::Combine($folder, $SyntaxFileName), $true)
							[System.IO.File]::Copy($SourceAliasFilePath, [System.IO.Path]::Combine($folder, $AliasFileName), $true)
						}
						
					}
					
				}
				catch { }
				
			}
			
			function Write-File
			{
				param ([string]$Path,
					[string]$Value)
				try
				{
					$filewriter = New-Object System.IO.StreamWriter ($Path, $false, [System.Text.Encoding]::UTF8)
					$filewriter.Write($Value)
					$filewriter.Close()
				}
				catch
				{
					Write-Error $_.Exception.Message
				}
			}
			
			function Save-Command
			{
				param ([System.IO.StreamWriter]$filewriter,
					[System.IO.StreamWriter]$syntaxWriter,
					[string]$extensionName,
					[string]$extensionType,
					$command)
				
				$CmdletStringBuilder = New-Object System.Text.StringBuilder
				$commandName = $command.Name.Trim()
				
				try
				{
					$commandHelp = Get-Help $commandName -Full -ErrorAction 'Continue'
				}
				catch
				{
					$commandHelp = $null
				}
				
				$link = $null
				[void]$CmdletStringBuilder.Append('[')
				[void]$CmdletStringBuilder.Append($commandName)
				[void]$CmdletStringBuilder.Append('@@')
				[void]$CmdletStringBuilder.Append("$extensionType,$extensionName")
				[void]$CmdletStringBuilder.Append('@@')
				if ($commandHelp -ne $null)
				{
					[void]$CmdletStringBuilder.Append(($commandHelp.Synopsis | Out-String -OutBuffer 10000).TrimEnd().Replace("`r", "").Replace("`n", " "))
					if ($commandHelp.RelatedLinks.navigationLink -is [System.Array])
					{
						$link = ([string]$commandHelp.RelatedLinks.navigationLink[0].uri).Trim()
					}
					else
					{
						$link = ([string]$helpText.relatedLinks.navigationLink.uri).Trim()
					}
					[void]$CmdletStringBuilder.Append('@@')
					if (-not [System.String]::IsNullOrEmpty($link))
					{
						[void]$CmdletStringBuilder.Append($link)
					}
				}
				else
				{
					[void]$CmdletStringBuilder.Append('@@')
				}
				
				[void]$CmdletStringBuilder.Append(']')
				$filewriter.WriteLine($CmdletStringBuilder.ToString())
				#-------------------------------
				# Process Syntax
				#-------------------------------
				[void]$CmdletStringBuilder.Remove(0, $CmdletStringBuilder.Length)
				
				if ($command.CommandType -eq [System.Management.Automation.CommandTypes]::Cmdlet)
				{
					$syntax = $command.Definition
				}
				else
				{
					$syntax = Get-Command $command -Syntax
				}
				
				Process-Syntax $CmdletStringBuilder $command.Name $syntax
				try
				{
					$filewriter.WriteLine($CmdletStringBuilder.ToString().TrimEnd())
				}
				catch
				{
					Write-Error $_.Exception.Message
				}
				try
				{
					$syntaxWriter.WriteLine($CmdletStringBuilder.ToString().TrimEnd())
				}
				catch
				{
					Write-Error $_.Exception.Message
				}
				Load-Parameters $command.ParameterSets $filewriter
			}
			
			function Process-Syntax([System.Text.StringBuilder]$stringBuilder, [string]$CommandName, $syntax)
			{
				if ($syntax -is [string])
				{
					$syntax = [string]$syntax
					$lines = $syntax.Split("`n")
					
					foreach ($line in $lines)
					{
						if ([string]::IsNullOrEmpty($line) -eq $false -and $line.StartsWith($CommandName, [System.StringComparison]::OrdinalIgnoreCase) -eq $true)
						{
							[void]$stringBuilder.AppendLine($line.Trim())
						}
					}
				}
				else
				{
					foreach ($s in $syntax)
					{
						Process-Syntax $stringBuilder $CommandName $s
					}
				}
			}
			
			function Load-Parameters
			{
				param ($parametersets,
					[System.IO.StreamWriter]$filewriter)
				
				$currentCommands = @{ }
				$builder = New-Object System.Text.StringBuilder
				$containsCommonParams = $false
				[void]$builder.Append('Parameters=');
				foreach ($paramset in $parametersets)
				{
					if ($paramset)
					{
						foreach ($param in $paramset.Parameters)
						{
							if (-not $currentCommands.ContainsKey($param.Name))
							{
								$currentCommands.Add($param.Name, $null)
								
								[void]$builder.Append(('{0}|{1}|' -f $param.Name, $param.ParameterType.FullName))
								
								if ($param.Aliases.Count -gt 0)
								{
									for ($index = 0; $index -lt $param.Aliases.Count; $index++)
									{
										$alias = $param.Aliases[$index]
										if ($index -gt 0)
										{
											[void]$builder.Append(' ')
										}
										[void]$builder.Append($alias.ToString().Trim())
										
									}
								}
								[void]$builder.Append(';')
							}
						}
					}
				}
				
				$filewriter.WriteLine($builder.ToString())
			}
			#endregion
			
			foreach ($item in $ModuleSelection)
			{
				$extension = $null
				try
				{
					if ($item.IsSnapin)
					{
						$extension = Add-PSSnapin -Name $item.Name -PassThru
					}
					else
					{
						$extension = Import-Module -Name $item.Name -PassThru
						
						#$extension = Get-Module -Name $item.Name -ListAvailable
						
						if ($extension -eq $null)
						{
							$extension = Get-Module -Name $item.Name -ListAvailable
							#					$extension = Import-Module -Name $item.Name -PassThru
						}
					}
					
					if ($extension -eq $null)
					{
						return
					}
					
					if ($extension.Length -gt 1)
					{
						$extension = $extension[0]
					}
					
					Build-ModuleCache $extension $Folders
				}
				catch [System.Exception]
				{
					Write-Error "Error: " + $_.Message
					$formBuildModuleCache.DialogResult = 'None'
				}
			}
		}`
					   -CompletedScript {
			Param ($Job)
			$results = Receive-Job -Job $Job
			
			if ($results)
			{
				$textboxStatus.AppendText(($results | Out-String))
			}
	
		#Set to ready state:
			$buttonBuild.ImageIndex = -1
			$buttonBuild.Enabled = $checkedlistboxModules.CheckedItems.Count -gt 1
			$buttonBrowse.Enabled = $true
			$formBuildModuleCache.Cursor = 'Default'
			$textboxStatus.AppendText("`r`n>> Build Complete")
		}`
					   -UpdateScript {
			Param ($Job)
			#$results = Receive-Job -Job $Job -Keep
			#Animate the Button
			if ($buttonBuild.ImageList -ne $null)
			{
				if ($buttonBuild.ImageIndex -lt $buttonBuild.ImageList.Images.Count - 1)
				{
					$buttonBuild.ImageIndex += 1
				}
				else
				{
					$buttonBuild.ImageIndex = 0
				}
			}
		}`
					   -ArgumentList $ModuleSelection, $folders
		
		#======================================================
	}
	
	$buttonBrowse_Click= {
		
		if ($openfiledialog1.ShowDialog() -eq 'OK')
		{
	
			try
			{
				
				$members = @{
					'Name' = $openfiledialog1.FileName;
					'IsSnapin' = $false
				}
				
				$selection = New-Object System.Management.Automation.PSObject -Property $members
				Export-ModuleSelection $selection
				
			}
			catch
			{
				$textboxStatus.AppendText($_.Exception.Message)
			}
		}
	}
	
	$jobTracker_FormClosed=[System.Windows.Forms.FormClosedEventHandler]{
	#Event Argument: $_ = [System.Windows.Forms.FormClosedEventArgs]
		#Stop any pending jobs
		Stop-JobTracker
	}
	
	$timerJobTracker_Tick={
		Update-JobTracker
	}
	
	#region Job Tracker
	$JobTrackerList = New-Object System.Collections.ArrayList
	function Add-JobTracker
	{
		<#
			.SYNOPSIS
				Add a new job to the JobTracker and starts the timer.
		
			.DESCRIPTION
				Add a new job to the JobTracker and starts the timer.
		
			.PARAMETER  Name
				The name to assign to the Job
		
			.PARAMETER  JobScript
				The script block that the Job will be performing. 
				Important: Do not access form controls from this script block.
		
			.PARAMETER ArgumentList
				The arguments to pass to the job
		
			.PARAMETER  CompleteScript
				The script block that will be called when the job is complete.
				The job is passed as an argument. The Job argument is null when the job fails.
		
			.PARAMETER  UpdateScript
				The script block that will be called each time the timer ticks. 
				The job is passed as an argument. Use this to get the Job's progress.
		
			.EXAMPLE
				Job-Begin -Name "JobName" `
				-JobScript {	
					Param($Argument1)#Pass any arguments using the ArgumentList parameter
					#Important: Do not access form controls from this script block.
					Get-WmiObject Win32_Process -Namespace "root\CIMV2"
				}`
				-CompletedScript {
					Param($Job)		
					$results = Receive-Job -Job $Job		
				}`
				-UpdateScript {
					Param($Job)
					#$results = Receive-Job -Job $Job -Keep
				}
		
			.LINK
				
		#>
		
		Param(
		[ValidateNotNull()]
		[Parameter(Mandatory=$true)]
		[string]$Name, 
		[ValidateNotNull()]
		[Parameter(Mandatory=$true)]
		[ScriptBlock]$JobScript,
		$ArgumentList = $null,
		[ScriptBlock]$CompletedScript,
		[ScriptBlock]$UpdateScript)
		
		#Start the Job
		$job = Start-Job -Name $Name -ScriptBlock $JobScript -ArgumentList $ArgumentList
		
		if($job -ne $null)
		{
			#Create a Custom Object to keep track of the Job & Script Blocks
			$members = @{	'Job' = $Job;
							'CompleteScript' = $CompletedScript;
							'UpdateScript' = $UpdateScript}
			
			$psObject = New-Object System.Management.Automation.PSObject -Property $members
			
			[void]$JobTrackerList.Add($psObject)	
			
			#Start the Timer
			if(-not $timerJobTracker.Enabled)
			{
				$timerJobTracker.Start()
			}
		}
		elseif($CompletedScript -ne $null)
		{
			#Failed
			Invoke-Command -ScriptBlock $CompletedScript -ArgumentList $null
		}
	
	}
	
	function Update-JobTracker
	{
		<#
			.SYNOPSIS
				Checks the status of each job on the list.
		#>
		
		#Poll the jobs for status updates
		$timerJobTracker.Stop() #Freeze the Timer
		
		for($index = 0; $index -lt $JobTrackerList.Count; $index++)
		{
			$psObject = $JobTrackerList[$index]
			
			if($psObject -ne $null) 
			{
				if($psObject.Job -ne $null)
				{
					if ($psObject.Job.State -eq 'Blocked')
	                {
	                    #Try to unblock the job
	                    Receive-Job $psObject.Job | Out-Null
	                }
	                elseif($psObject.Job.State -ne 'Running')
					{				
						#Call the Complete Script Block
						if($psObject.CompleteScript -ne $null)
						{
							#$results = Receive-Job -Job $psObject.Job
							Invoke-Command -ScriptBlock $psObject.CompleteScript -ArgumentList $psObject.Job
						}
						
						$JobTrackerList.RemoveAt($index)
						Remove-Job -Job $psObject.Job
						$index-- #Step back so we don't skip a job
					}
					elseif($psObject.UpdateScript -ne $null)
					{
						#Call the Update Script Block
						Invoke-Command -ScriptBlock $psObject.UpdateScript -ArgumentList $psObject.Job
					}
				}
			}
			else
			{
				$JobTrackerList.RemoveAt($index)
				$index-- #Step back so we don't skip a job
			}
		}
		
		if($JobTrackerList.Count -gt 0)
		{
			$timerJobTracker.Start()#Resume the timer	
		}	
	}
	
	function Stop-JobTracker
	{
		<#
			.SYNOPSIS
				Stops and removes all Jobs from the list.
		#>
		#Stop the timer
		$timerJobTracker.Stop()
		
		#Remove all the jobs
		while($JobTrackerList.Count -gt 0)
		{
			$job = $JobTrackerList[0].Job
			$JobTrackerList.RemoveAt(0)
			Stop-Job $job
			Remove-Job $job
		}
	}
	#endregion
	
	
	# --End User Generated Script--
	#----------------------------------------------
	#region Generated Events
	#----------------------------------------------
	
	$Form_StateCorrection_Load=
	{
		#Correct the initial state of the form to prevent the .Net maximized form issue
		$formBuildModuleCache.WindowState = $InitialFormWindowState
	}
	
	$Form_Cleanup_FormClosed=
	{
		#Remove all event handlers from the controls
		try
		{
			$buttonBuild.remove_Click($buttonBuild_Click)
			$buttonBrowse.remove_Click($buttonBrowse_Click)
			$checkedlistboxModules.remove_ItemCheck($checkedlistboxModules_ItemCheck)
			$formBuildModuleCache.remove_FormClosed($jobTracker_FormClosed)
			$formBuildModuleCache.remove_Load($FormEvent_Load)
			$timerJobTracker.remove_Tick($timerJobTracker_Tick)
			$formBuildModuleCache.remove_Load($Form_StateCorrection_Load)
			$formBuildModuleCache.remove_FormClosed($Form_Cleanup_FormClosed)
		}
		catch [Exception]
		{ }
	}
	#endregion Generated Events

	#----------------------------------------------
	#region Generated Form Code
	#----------------------------------------------
	$formBuildModuleCache.SuspendLayout()
	#
	# formBuildModuleCache
	#
	$formBuildModuleCache.Controls.Add($textboxStatus)
	$formBuildModuleCache.Controls.Add($buttonBuild)
	$formBuildModuleCache.Controls.Add($buttonBrowse)
	$formBuildModuleCache.Controls.Add($buttonCancel)
	$formBuildModuleCache.Controls.Add($labelModules)
	$formBuildModuleCache.Controls.Add($checkedlistboxModules)
	$formBuildModuleCache.AcceptButton = $buttonBuild
	$formBuildModuleCache.AutoScaleDimensions = '11, 24'
	$formBuildModuleCache.AutoScaleMode = 'Font'
	$formBuildModuleCache.ClientSize = '1258, 683'
	$formBuildModuleCache.Margin = '11, 11, 11, 11'
	$formBuildModuleCache.MaximizeBox = $False
	$formBuildModuleCache.MinimizeBox = $False
	$formBuildModuleCache.MinimumSize = '713, 500'
	$formBuildModuleCache.Name = 'formBuildModuleCache'
	$formBuildModuleCache.ShowIcon = $False
	$formBuildModuleCache.StartPosition = 'CenterScreen'
	$formBuildModuleCache.Text = 'Build Module Cache'
	$formBuildModuleCache.add_FormClosed($jobTracker_FormClosed)
	$formBuildModuleCache.add_Load($FormEvent_Load)
	#
	# textboxStatus
	#
	$textboxStatus.Anchor = 'Bottom, Left, Right'
	$textboxStatus.BackColor = 'Window'
	$textboxStatus.Font = 'Courier New, 8.25pt'
	$textboxStatus.Location = '22, 456'
	$textboxStatus.Margin = '6, 6, 6, 6'
	$textboxStatus.Multiline = $True
	$textboxStatus.Name = 'textboxStatus'
	$textboxStatus.ReadOnly = $True
	$textboxStatus.ScrollBars = 'Both'
	$textboxStatus.Size = '1062, 202'
	$textboxStatus.TabIndex = 9
	#
	# buttonBuild
	#
	$buttonBuild.Anchor = 'Top, Right'
	$buttonBuild.ImageList = $imagelistButtonBusyAnimation
	$buttonBuild.Location = '1098, 50'
	$buttonBuild.Margin = '6, 6, 6, 6'
	$buttonBuild.Name = 'buttonBuild'
	$buttonBuild.Size = '138, 42'
	$buttonBuild.TabIndex = 0
	$buttonBuild.Text = '&Build'
	$buttonBuild.TextImageRelation = 'ImageBeforeText'
	$buttonBuild.UseVisualStyleBackColor = $True
	$buttonBuild.add_Click($buttonBuild_Click)
	#
	# buttonBrowse
	#
	$buttonBrowse.Anchor = 'Top, Right'
	$buttonBrowse.Location = '1098, 103'
	$buttonBrowse.Margin = '6, 6, 6, 6'
	$buttonBrowse.Name = 'buttonBrowse'
	$buttonBrowse.Size = '138, 42'
	$buttonBrowse.TabIndex = 7
	$buttonBrowse.Text = 'B&rowse'
	$buttonBrowse.UseVisualStyleBackColor = $True
	$buttonBrowse.add_Click($buttonBrowse_Click)
	#
	# buttonCancel
	#
	$buttonCancel.Anchor = 'Top, Right'
	$buttonCancel.CausesValidation = $False
	$buttonCancel.DialogResult = 'Cancel'
	$buttonCancel.Location = '1098, 157'
	$buttonCancel.Margin = '6, 6, 6, 6'
	$buttonCancel.Name = 'buttonCancel'
	$buttonCancel.Size = '138, 42'
	$buttonCancel.TabIndex = 6
	$buttonCancel.Text = '&Cancel'
	$buttonCancel.UseVisualStyleBackColor = $True
	#
	# labelModules
	#
	$labelModules.AutoSize = $True
	$labelModules.Location = '22, 17'
	$labelModules.Margin = '11, 0, 11, 0'
	$labelModules.Name = 'labelModules'
	$labelModules.Size = '93, 25'
	$labelModules.TabIndex = 2
	$labelModules.Text = 'Modules:'
	#
	# checkedlistboxModules
	#
	$checkedlistboxModules.Anchor = 'Top, Bottom, Left, Right'
	$checkedlistboxModules.CheckOnClick = $True
	$checkedlistboxModules.Font = 'Microsoft Sans Serif, 8.25pt'
	$checkedlistboxModules.FormattingEnabled = $True
	$checkedlistboxModules.Location = '22, 50'
	$checkedlistboxModules.Margin = '6, 6, 6, 6'
	$checkedlistboxModules.Name = 'checkedlistboxModules'
	$checkedlistboxModules.Size = '1062, 388'
	$checkedlistboxModules.Sorted = $True
	$checkedlistboxModules.TabIndex = 1
	$checkedlistboxModules.add_ItemCheck($checkedlistboxModules_ItemCheck)
	#
	# timerJobTracker
	#
	$timerJobTracker.add_Tick($timerJobTracker_Tick)
	#
	# openfiledialog1
	#
	$openfiledialog1.FileName = 'openfiledialog1'
	$openfiledialog1.Filter = 'PowerShell Module Files (*.psd1, *.psm1,  *.dll)|*.psd1; *.psm1; *.dll'
	#
	# imagelistButtonBusyAnimation
	#
	$Formatter_binaryFomatter = New-Object System.Runtime.Serialization.Formatters.Binary.BinaryFormatter
	#region Binary Data
	$System_IO_MemoryStream = New-Object System.IO.MemoryStream (,[byte[]][System.Convert]::FromBase64String('
AAEAAAD/////AQAAAAAAAAAMAgAAAFdTeXN0ZW0uV2luZG93cy5Gb3JtcywgVmVyc2lvbj00LjAu
MC4wLCBDdWx0dXJlPW5ldXRyYWwsIFB1YmxpY0tleVRva2VuPWI3N2E1YzU2MTkzNGUwODkFAQAA
ACZTeXN0ZW0uV2luZG93cy5Gb3Jtcy5JbWFnZUxpc3RTdHJlYW1lcgEAAAAERGF0YQcCAgAAAAkD
AAAADwMAAAB2CgAAAk1TRnQBSQFMAgEBCAEAAVABAAFQAQABEAEAARABAAT/ASEBAAj/AUIBTQE2
BwABNgMAASgDAAFAAwABMAMAAQEBAAEgBgABMP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/
AP8AugADwgH/AzsB/wM7Af8DwgH/MAADwgH/A1sB/wOCAf8DwgH/sAADOwH/AwAB/wMAAf8DOwH/
MAADggH/AzsB/wM7Af8DWwH/gAADwgH/AzsB/wM7Af8DwgH/IAADOwH/AwAB/wMAAf8DOwH/A8IB
/wNbAf8DggH/A8IB/xAAA8IB/wM7Af8DOwH/A8IB/wNbAf8DOwH/AzsB/wNbAf8EAAOSAf8DkgH/
A8IB/3AAAzsB/wMAAf8DAAH/AzsB/yAAA8IB/wM7Af8DOwH/A8IB/wOCAf8DOwH/AzsB/wOCAf8Q
AAM7Af8DAAH/AwAB/wM7Af8DwgH/A1sB/wOCAf8DwgH/A5IB/wOCAf8DggH/A5IB/3AAAzsB/wMA
Af8DAAH/AzsB/zAAA1sB/wM7Af8DOwH/A1sB/xAAAzsB/wMAAf8DAAH/AzsB/xAAA5IB/wOSAf8D
kgH/A8IB/3AAA8IB/wM7Af8DOwH/A8IB/zAAA8IB/wNbAf8DggH/A8IB/xAAA8IB/wM7Af8DOwH/
A8IB/xAAA8IB/wOSAf8DkgH/A8IB/zgAA8IB/wM7Af8DOwH/A8IB/zAAA8IB/wOCAf8DWwH/A8IB
/zAAA8IB/wPCAf8DkgH/A8IB/zQAA8IB/wPCAf80AAM7Af8DAAH/AwAB/wM7Af8wAANbAf8DOwH/
AzsB/wNbAf8wAAOSAf8DggH/A4IB/wOSAf8wAAPCAf8DwgH/A8IB/wPCAf8wAAM7Af8DAAH/AwAB
/wM7Af8wAAOCAf8DOwH/AzsB/wOCAf8wAAPCAf8DggH/A5IB/wOSAf8wAAPCAf8DwgH/A8IB/wPC
Af8wAAPCAf8DOwH/AzsB/wPCAf8wAAPCAf8DggH/A1sB/wPCAf8wAAPCAf8DkgH/A5IB/wPCAf80
AAPCAf8DwgH/EAADwgH/A8IB/xQAA8IB/wOCAf8DWwH/A8IB/zAAA8IB/wOSAf8DkgH/A8IB/zQA
A8IB/wPCAf9UAAPCAf8DwgH/A8IB/wPCAf8QAANbAf8DOwH/AzsB/wNbAf8wAAOSAf8DggH/A5IB
/wOSAf8wAAPCAf8DwgH/A8IB/wPCAf9QAAPCAf8DwgH/A8IB/wPCAf8DwgH/A8IB/wOSAf8DwgH/
A4IB/wM7Af8DOwH/A4IB/yQAA8IB/wPCAf8EAAPCAf8DggH/A5IB/wOSAf8wAAPCAf8DwgH/A8IB
/wPCAf9UAAPCAf8DwgH/BAADkgH/A4IB/wOCAf8DkgH/A8IB/wOCAf8DWwH/A8IB/yAAA8IB/wPC
Af8DwgH/A8IB/wPCAf8DkgH/A5IB/wPCAf80AAPCAf8DwgH/ZAADkgH/A5IB/wOSAf8DkgH/MAAD
wgH/A8IB/wPCAf8DwgH/sAADwgH/A5IB/wOSAf8DwgH/NAADwgH/A8IB/7QAA8IB/wPCAf8DkgH/
A8IB/zQAA8IB/wPCAf+0AAOSAf8DggH/A4IB/wOSAf8wAAPCAf8DwgH/A8IB/wPCAf+gAAPCAf8D
WwH/A4IB/wPCAf8DkgH/A5IB/wOSAf8DwgH/BAADwgH/A8IB/xQAA8IB/wPCAf8DkgH/A8IB/wPC
Af8DwgH/A8IB/wPCAf8kAAPCAf8DwgH/dAADggH/AzsB/wM7Af8DggH/A8IB/wOSAf8DkgH/A8IB
/wPCAf8DwgH/A8IB/wPCAf8QAAOSAf8DggH/A4IB/wOSAf8EAAPCAf8DwgH/JAADwgH/A8IB/wPC
Af8DwgH/cAADWwH/AzsB/wM7Af8DggH/EAADwgH/A8IB/wPCAf8DwgH/EAADkgH/A5IB/wOSAf8D
kgH/MAADwgH/A8IB/wPCAf8DwgH/cAADwgH/A1sB/wNbAf8DwgH/FAADwgH/A8IB/xQAA8IB/wOS
Af8DkgH/A8IB/zQAA8IB/wPCAf9sAAPCAf8DOwH/AzsB/wPCAf8wAAPCAf8DWwH/A4IB/wPCAf8w
AAPCAf8DwgH/A5IB/wPCAf80AAPCAf8DwgH/NAADOwH/AwAB/wMAAf8DOwH/MAADggH/AzsB/wM7
Af8DWwH/MAADkgH/A4IB/wOCAf8DkgH/MAADwgH/A8IB/wPCAf8DwgH/MAADOwH/AwAB/wMAAf8D
OwH/MAADWwH/AzsB/wM7Af8DggH/MAADkgH/A5IB/wOSAf8DkgH/MAADwgH/A8IB/wPCAf8DwgH/
MAADwgH/AzsB/wM7Af8DwgH/MAADwgH/A1sB/wNbAf8DwgH/MAADwgH/A5IB/wOSAf8DwgH/NAAD
wgH/A8IB/3wAA8IB/wM7Af8DOwH/A8IB/zAAA8IB/wNbAf8DggH/A8IB/zAAA8IB/wPCAf8DkgH/
A8IB/xAAA8IB/wM7Af8DOwH/A8IB/1AAAzsB/wMAAf8DAAH/AzsB/zAAA4IB/wM7Af8DOwH/A1sB
/zAAA5IB/wOCAf8DggH/A5IB/xAAAzsB/wMAAf8DAAH/AzsB/1AAAzsB/wMAAf8DAAH/AzsB/zAA
A1sB/wM7Af8DOwH/A4IB/wOSAf8DOwH/AzsB/wPCAf8gAAOSAf8DkgH/A5IB/wOSAf8DwgH/A1sB
/wOCAf8DwgH/AzsB/wMAAf8DAAH/AzsB/1AAA8IB/wM7Af8DOwH/A8IB/zAAA8IB/wOCAf8DWwH/
A8IB/wM7Af8DAAH/AwAB/wM7Af8gAAPCAf8DkgH/A5IB/wPCAf8DggH/AzsB/wM7Af8DWwH/A8IB
/wM7Af8DOwH/A8IB/6AAAzsB/wMAAf8DAAH/AzsB/zAAA1sB/wM7Af8DOwH/A4IB/7AAA8IB/wM7
Af8DOwH/A8IB/zAAA8IB/wOCAf8DWwH/A8IB/xgAAUIBTQE+BwABPgMAASgDAAFAAwABMAMAAQEB
AAEBBQABgAEBFgAD/4EABP8B/AE/AfwBPwT/AfwBPwH8AT8D/wHDAfwBAwHAASMD/wHDAfwBAwHA
AQMD/wHDAf8DwwP/AcMB/wPDAf8B8AH/AfAB/wHwAf8B+QH/AfAB/wHwAf8B8AH/AfAB/wHwAf8B
8AH/AfAB/wHwAf8B8AH/AfAB/wHwAf8B+QHnAcMB/wHDAf8B5wL/AsMB/wHDAf8BwwL/AcABAwH+
AUMB/wHDAv8B5AEDAfwBAwH/AecC/wH8AT8B/AE/BP8B/AE/Af4BfwT/AfwBPwH+AX8E/wH8AT8B
/AE/BP8BwAEnAcABPwHnA/8BwAEDAcIBfwHDA/8DwwH/AcMD/wHDAecBwwH/AecD/wEPAf8BDwH/
AQ8B/wGfAf8BDwH/AQ8B/wEPAf8BDwH/AQ8B/wEPAf8BDwH/AQ8B/wEPAf8BDwH/AQ8B/wGfA/8B
wwH/AcMB/wLDAv8BwwH/AcMB/wLDAv8BwwH/AcABPwHAAQMC/wHDAf8BwAE/AcABAwT/AfwBPwH8
AT8E/wH8AT8B/AE/Cw=='))
	#endregion
	$imagelistButtonBusyAnimation.ImageStream = $Formatter_binaryFomatter.Deserialize($System_IO_MemoryStream)
	$Formatter_binaryFomatter = $null
	$System_IO_MemoryStream = $null
	$imagelistButtonBusyAnimation.TransparentColor = 'Transparent'
	$formBuildModuleCache.ResumeLayout()
	#endregion Generated Form Code

	#----------------------------------------------

	#Save the initial state of the form
	$InitialFormWindowState = $formBuildModuleCache.WindowState
	#Init the OnLoad event to correct the initial state of the form
	$formBuildModuleCache.add_Load($Form_StateCorrection_Load)
	#Clean up the control events
	$formBuildModuleCache.add_FormClosed($Form_Cleanup_FormClosed)
	#Show the Form
	return $formBuildModuleCache.ShowDialog()

} #End Function

#Call the form
Call-Build_Module_Cache_psf | Out-Null

# SIG # Begin signature block
# MIITFgYJKoZIhvcNAQcCoIITBzCCEwMCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUGgoPE33FLK3+kYo6I2mdL762
# zICggg2lMIIEFDCCAvygAwIBAgILBAAAAAABL07hUtcwDQYJKoZIhvcNAQEFBQAw
# VzELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2ExEDAOBgNV
# BAsTB1Jvb3QgQ0ExGzAZBgNVBAMTEkdsb2JhbFNpZ24gUm9vdCBDQTAeFw0xMTA0
# MTMxMDAwMDBaFw0yODAxMjgxMjAwMDBaMFIxCzAJBgNVBAYTAkJFMRkwFwYDVQQK
# ExBHbG9iYWxTaWduIG52LXNhMSgwJgYDVQQDEx9HbG9iYWxTaWduIFRpbWVzdGFt
# cGluZyBDQSAtIEcyMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAlO9l
# +LVXn6BTDTQG6wkft0cYasvwW+T/J6U00feJGr+esc0SQW5m1IGghYtkWkYvmaCN
# d7HivFzdItdqZ9C76Mp03otPDbBS5ZBb60cO8eefnAuQZT4XljBFcm05oRc2yrmg
# jBtPCBn2gTGtYRakYua0QJ7D/PuV9vu1LpWBmODvxevYAll4d/eq41JrUJEpxfz3
# zZNl0mBhIvIG+zLdFlH6Dv2KMPAXCae78wSuq5DnbN96qfTvxGInX2+ZbTh0qhGL
# 2t/HFEzphbLswn1KJo/nVrqm4M+SU4B09APsaLJgvIQgAIMboe60dAXBKY5i0Eex
# +vBTzBj5Ljv5cH60JQIDAQABo4HlMIHiMA4GA1UdDwEB/wQEAwIBBjASBgNVHRMB
# Af8ECDAGAQH/AgEAMB0GA1UdDgQWBBRG2D7/3OO+/4Pm9IWbsN1q1hSpwTBHBgNV
# HSAEQDA+MDwGBFUdIAAwNDAyBggrBgEFBQcCARYmaHR0cHM6Ly93d3cuZ2xvYmFs
# c2lnbi5jb20vcmVwb3NpdG9yeS8wMwYDVR0fBCwwKjAooCagJIYiaHR0cDovL2Ny
# bC5nbG9iYWxzaWduLm5ldC9yb290LmNybDAfBgNVHSMEGDAWgBRge2YaRQ2XyolQ
# L30EzTSo//z9SzANBgkqhkiG9w0BAQUFAAOCAQEATl5WkB5GtNlJMfO7FzkoG8IW
# 3f1B3AkFBJtvsqKa1pkuQJkAVbXqP6UgdtOGNNQXzFU6x4Lu76i6vNgGnxVQ380W
# e1I6AtcZGv2v8Hhc4EvFGN86JB7arLipWAQCBzDbsBJe/jG+8ARI9PBw+DpeVoPP
# PfsNvPTF7ZedudTbpSeE4zibi6c1hkQgpDttpGoLoYP9KOva7yj2zIhd+wo7AKvg
# IeviLzVsD440RZfroveZMzV+y5qKu0VN5z+fwtmK+mWybsd+Zf/okuEsMaL3sCc2
# SI8mbzvuTXYfecPlf5Y1vC0OzAGwjn//UYCAp5LUs0RGZIyHTxZjBzFLY7Df8zCC
# BJ8wggOHoAMCAQICEhEh1pmnZJc+8fhCfukZzFNBFDANBgkqhkiG9w0BAQUFADBS
# MQswCQYDVQQGEwJCRTEZMBcGA1UEChMQR2xvYmFsU2lnbiBudi1zYTEoMCYGA1UE
# AxMfR2xvYmFsU2lnbiBUaW1lc3RhbXBpbmcgQ0EgLSBHMjAeFw0xNjA1MjQwMDAw
# MDBaFw0yNzA2MjQwMDAwMDBaMGAxCzAJBgNVBAYTAlNHMR8wHQYDVQQKExZHTU8g
# R2xvYmFsU2lnbiBQdGUgTHRkMTAwLgYDVQQDEydHbG9iYWxTaWduIFRTQSBmb3Ig
# TVMgQXV0aGVudGljb2RlIC0gRzIwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEK
# AoIBAQCwF66i07YEMFYeWA+x7VWk1lTL2PZzOuxdXqsl/Tal+oTDYUDFRrVZUjtC
# oi5fE2IQqVvmc9aSJbF9I+MGs4c6DkPw1wCJU6IRMVIobl1AcjzyCXenSZKX1GyQ
# oHan/bjcs53yB2AsT1iYAGvTFVTg+t3/gCxfGKaY/9Sr7KFFWbIub2Jd4NkZrItX
# nKgmK9kXpRDSRwgacCwzi39ogCq1oV1r3Y0CAikDqnw3u7spTj1Tk7Om+o/SWJMV
# TLktq4CjoyX7r/cIZLB6RA9cENdfYTeqTmvT0lMlnYJz+iz5crCpGTkqUPqp0Dw6
# yuhb7/VfUfT5CtmXNd5qheYjBEKvAgMBAAGjggFfMIIBWzAOBgNVHQ8BAf8EBAMC
# B4AwTAYDVR0gBEUwQzBBBgkrBgEEAaAyAR4wNDAyBggrBgEFBQcCARYmaHR0cHM6
# Ly93d3cuZ2xvYmFsc2lnbi5jb20vcmVwb3NpdG9yeS8wCQYDVR0TBAIwADAWBgNV
# HSUBAf8EDDAKBggrBgEFBQcDCDBCBgNVHR8EOzA5MDegNaAzhjFodHRwOi8vY3Js
# Lmdsb2JhbHNpZ24uY29tL2dzL2dzdGltZXN0YW1waW5nZzIuY3JsMFQGCCsGAQUF
# BwEBBEgwRjBEBggrBgEFBQcwAoY4aHR0cDovL3NlY3VyZS5nbG9iYWxzaWduLmNv
# bS9jYWNlcnQvZ3N0aW1lc3RhbXBpbmdnMi5jcnQwHQYDVR0OBBYEFNSihEo4Whh/
# uk8wUL2d1XqH1gn3MB8GA1UdIwQYMBaAFEbYPv/c477/g+b0hZuw3WrWFKnBMA0G
# CSqGSIb3DQEBBQUAA4IBAQCPqRqRbQSmNyAOg5beI9Nrbh9u3WQ9aCEitfhHNmmO
# 4aVFxySiIrcpCcxUWq7GvM1jjrM9UEjltMyuzZKNniiLE0oRqr2j79OyNvy0oXK/
# bZdjeYxEvHAvfvO83YJTqxr26/ocl7y2N5ykHDC8q7wtRzbfkiAD6HHGWPZ1BZo0
# 8AtZWoJENKqA5C+E9kddlsm2ysqdt6a65FDT1De4uiAO0NOSKlvEWbuhbds8zkSd
# wTgqreONvc0JdxoQvmcKAjZkiLmzGybu555gxEaovGEzbM9OuZy5avCfN/61PU+a
# 003/3iCOTpem/Z8JvE3KGHbJsE2FUPKA0h0G9VgEB7EYMIIE5jCCA86gAwIBAgIQ
# D3G+iYSlUr2D5y/ELzPF6DANBgkqhkiG9w0BAQsFADB/MQswCQYDVQQGEwJVUzEd
# MBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRpb24xHzAdBgNVBAsTFlN5bWFudGVj
# IFRydXN0IE5ldHdvcmsxMDAuBgNVBAMTJ1N5bWFudGVjIENsYXNzIDMgU0hBMjU2
# IENvZGUgU2lnbmluZyBDQTAeFw0xNTA4MTIwMDAwMDBaFw0xODEwMTAyMzU5NTla
# MHkxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpDYWxpZm9ybmlhMQ0wCwYDVQQHEwRO
# YXBhMSIwIAYDVQQKFBlTQVBJRU4gVGVjaG5vbG9naWVzLCBJbmMuMSIwIAYDVQQD
# FBlTQVBJRU4gVGVjaG5vbG9naWVzLCBJbmMuMIIBIjANBgkqhkiG9w0BAQEFAAOC
# AQ8AMIIBCgKCAQEAwZqUHHSXh4kbcGg4h9gRD7D/ltVG5VI+/n5vfFAuKzcsftm9
# Kgh5kpjZHiuhG90in3qYQ2uYxyErTO1v7+399y+/7vjSh3MKf4VGhY5qieC08bb+
# 3z3zefGDp/9U3nNJj8YDpJ7lJWl4HDU5mnszlfUpKZQUYJ1Lj92EBvDsvukz8DJ2
# SrHwPQYZqL1qZ6v8uVraVVRhOQpFXCDq1QvzMt9xJGd/opRUvMasm0uvm/hS/kuJ
# 0TNtj9s8uKdUiM6KwlYyRZbdz/2B3l+LTjnKiXtkgnMakOLj1W9KjdDVrFDtGVMI
# taxI3yncU1qkSEftPd0+yZaefbnJS/UN2A6UwQIDAQABo4IBYjCCAV4wCQYDVR0T
# BAIwADAOBgNVHQ8BAf8EBAMCB4AwKwYDVR0fBCQwIjAgoB6gHIYaaHR0cDovL3N2
# LnN5bWNiLmNvbS9zdi5jcmwwZgYDVR0gBF8wXTBbBgtghkgBhvhFAQcXAzBMMCMG
# CCsGAQUFBwIBFhdodHRwczovL2Quc3ltY2IuY29tL2NwczAlBggrBgEFBQcCAjAZ
# DBdodHRwczovL2Quc3ltY2IuY29tL3JwYTATBgNVHSUEDDAKBggrBgEFBQcDAzBX
# BggrBgEFBQcBAQRLMEkwHwYIKwYBBQUHMAGGE2h0dHA6Ly9zdi5zeW1jZC5jb20w
# JgYIKwYBBQUHMAKGGmh0dHA6Ly9zdi5zeW1jYi5jb20vc3YuY3J0MB8GA1UdIwQY
# MBaAFJY7U/B5M5evfYPvLivMyreGHnJmMB0GA1UdDgQWBBQfoDZC6SEmEF6kHUon
# aYJz2Bv3nDANBgkqhkiG9w0BAQsFAAOCAQEAkKpfG9wjJ0gDATI4KTmQBgt0uiN9
# CWqVVO8P7j4RUANfVrwE0pQWPdtZOSDw3GURL98xWm6Dathkpv/FiGJL/6IRtfJ9
# 6zqfDL6rzI8pRpzWhPyxMMl7AImVfUpcEobJ+dnn2k1j9nF5UipkgapDPJUZqgBb
# UpNw69jKNwY0JCZPMt9CxsIrkxzsHJu072ZsXvYKmrD50GrKlvx5T4M5O4QEzU68
# 3qxfr5cYZzDQeKuH/v85tqg59d5N6tJnZxAjMCL6W24ToG6qQpsXcQRhYtLKR/OH
# q2teSjZhyyXzQEGETTYZA3SDkvjWI1+MlBk7jRyzXnqP2kZPIxLQlQF1hTGCBNsw
# ggTXAgEBMIGTMH8xCzAJBgNVBAYTAlVTMR0wGwYDVQQKExRTeW1hbnRlYyBDb3Jw
# b3JhdGlvbjEfMB0GA1UECxMWU3ltYW50ZWMgVHJ1c3QgTmV0d29yazEwMC4GA1UE
# AxMnU3ltYW50ZWMgQ2xhc3MgMyBTSEEyNTYgQ29kZSBTaWduaW5nIENBAhAPcb6J
# hKVSvYPnL8QvM8XoMAkGBSsOAwIaBQCgeDAYBgorBgEEAYI3AgEMMQowCKACgACh
# AoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAM
# BgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBR3tpQkD59RNNkb6gjlcBjvfw/K
# TTANBgkqhkiG9w0BAQEFAASCAQALa+TIHAdH5NXUlWtS3DD9c1cYNp3FJwj66+Ze
# wZEGwTTA7BFsv5nUPtUw6hXAQBzwsgJWwzHCvo5N3Ibbts4tGwzv04WD1J4t4uzI
# sF0mybU4Dxcrbn4GKysrIfSf2Pv3GG9zlQcxzcJA5Qx2cXJuTlQ/olyItyueRP9r
# kIJGP259K7lViUoENGg+/MAbu/sRPcSf0+35BPhLxpkqsZbDIs/w0xzB4Lr+8pHU
# j4hjy+hEiifhXohy+Hl1xzmULnx7zmr4qjN1P3FB/4GJt9XlWX0Am8sITTOkWPq4
# 5vl+oTr2u4XV9ishlmr7X4Uu9QHVWJmX5tNQF3IPMpvjCpSLoYICojCCAp4GCSqG
# SIb3DQEJBjGCAo8wggKLAgEBMGgwUjELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEds
# b2JhbFNpZ24gbnYtc2ExKDAmBgNVBAMTH0dsb2JhbFNpZ24gVGltZXN0YW1waW5n
# IENBIC0gRzICEhEh1pmnZJc+8fhCfukZzFNBFDAJBgUrDgMCGgUAoIH9MBgGCSqG
# SIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTE2MTAxMTE1MTYx
# NlowIwYJKoZIhvcNAQkEMRYEFM1YqpHGsvV31Ih0XDImHS39iqi8MIGdBgsqhkiG
# 9w0BCRACDDGBjTCBijCBhzCBhAQUY7gvq2H1g5CWlQULACScUCkz7HkwbDBWpFQw
# UjELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2ExKDAmBgNV
# BAMTH0dsb2JhbFNpZ24gVGltZXN0YW1waW5nIENBIC0gRzICEhEh1pmnZJc+8fhC
# fukZzFNBFDANBgkqhkiG9w0BAQEFAASCAQAt+aTsiL3TMYyoKVfXHDiqODB/Kr6d
# SBnvIgK6XPpeIEA/GXQ8Ws9/8ucdeLe/ekxZObOxbc+LddzEnyo759NA6Nw8ARdC
# CFNMi8hfMFZnTGPaGaN20/7VY8Vro6t3NrGiRygOpHNQEP56oZ+fb4Ye4m+3yOgN
# ThQOeH02ZuiywsJ73F9BUIkMyAaj3bFozJOs+RvdrzGt0yx2MIJxZWfU2mqLx/UT
# kPwYDYgHplRA5SGjf2IO5yV61KYGHJF1vlbMeLhSZR0bmH8AwOoViVqTNtMyOU1Q
# LAXvM0GlCel/F68w8rdAOEyj4F7w69NdExoLkti4FWGU5l4rU2i6hBrE
# SIG # End signature block