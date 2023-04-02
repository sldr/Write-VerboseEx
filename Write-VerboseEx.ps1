Function Write-VerboseEx
{
<#
.SYNOPSIS
    An extended Write-Verbose that supports time stamping and showing the caller in the message.

.DESCRIPTION
    An extended Write-Verbose that supports time stamping and showing the caller in the message.

.Parameter Message
    Specifies the message to use.

.Parameter Timestamp
    Specifies that the time stampe should be used. The default is $true (use -Timestamp:$false to disable).

.Parameter Caller
    Shows the function name that called Write-VerboseEx. If this was called from outside a function then the string "<ScriptBlock>" will be used instead. The default is $false.

.NOTES
    Written by Stephen L. De Rudder

.EXAMPLE
    PS > Write-VerboseEx -Timestamp -Caller "Hello World!"
    VERBOSE: 2022-04-22T02:44:22.6195663-05:00:<ScriptBlock>: Hello World!

    This produced a verbose message with a timestamp and caller.

.EXAMPLE
    PS > Write-VerboseEx "Hello PowerShell!"
    VERBOSE: 2022-04-22T02:44:22.6195663-05:00: Hello PowerShell!

    This produced a verbose message with a timestamp.
#>

    param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [Alias('Msg')]
        [AllowEmptyString()]
        [string]
        ${Message},
        [switch]
        ${Timestamp}=$true,
        [switch]
        ${Caller}=$false)

    begin
    {
        try {
            $outBuffer = $null
            if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
            {
                $PSBoundParameters['OutBuffer'] = 1
            }
            $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Microsoft.PowerShell.Utility\Write-Verbose', [System.Management.Automation.CommandTypes]::Cmdlet)
            $outIgnore = $null
            $PSBoundParameters.Remove('Caller') | Out-Null
            $PSBoundParameters.Remove('Timestamp') | Out-Null
            if ($PSBoundParameters.TryGetValue('Message', [ref]$outIgnore)) {
                $Prefix = switch ($Timestamp) {
                    $true {
                        switch ($Caller) {
                            $true {
                                "$(Get-Date -Format o):$((Get-PSCallStack)[1].FunctionName): "
                            }
                            $false {
                                "$(Get-Date -Format o): "
                            }
                        }
                    }
                    $false {
                        switch ($Caller) {
                            $true {
                                "$((Get-PSCallStack)[1].FunctionName): "
                            }
                            $false {
                                ""
                            }
                        }
                    }
                }
                $PSBoundParameters['Message'] = "$Prefix$($PSBoundParameters['Message'])"
            }
            $scriptCmd = {& $wrappedCmd @PSBoundParameters }
            $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
            $steppablePipeline.Begin($PSCmdlet)
        } catch {
            throw
        }
    }

    process
    {
        try {
            $Prefix = switch ($Timestamp) {
                $true {
                    switch ($Caller) {
                        $true {
                            "$(Get-Date -Format o):$((Get-PSCallStack)[1].FunctionName): "
                        }
                        $false {
                            "$(Get-Date -Format o): "
                        }
                    }
                }
                $false {
                    switch ($Caller) {
                        $true {
                            "$((Get-PSCallStack)[1].FunctionName): "
                        }
                        $false {
                            ""
                        }
                    }
                }
            }
            $steppablePipeline.Process("$Prefix$_")
        } catch {
            throw
        }
    }

    end
    {
        try {
            $steppablePipeline.End()
        } catch {
            throw
        }
    }
}

Function Test-VerboseEx1
{
    [CmdletBinding()]
    param()
    Write-VerboseEx -Caller "In Test1."
}

Function Test-VerboseEx2
{
    [CmdletBinding()]
    param()
    Write-VerboseEx -Caller "In Test2!"
    Write-VerboseEx -Caller "Calling Test1"
    Test-VerboseEx1 -Verbose
    Write-VerboseEx -Caller "Called  Test1"
}

"SLDR" | Write-VerboseEx -Verbose
"no time stamp SLDR" | Write-VerboseEx -Verbose -Timestamp:$false
"no ts caller SLDR" | Write-VerboseEx -Verbose -Timestamp:$false -Caller
Write-VerboseEx -Verbose "SLDR"
"SL","DR" | Write-VerboseEx -Verbose
Test-VerboseEx1 -Verbose
Test-VerboseEx2 -Verbose
