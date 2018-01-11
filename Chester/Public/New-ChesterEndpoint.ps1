



function New-ChesterEndpoint {

    [CmdletBinding(DefaultParameterSetName = 'default')]
    param (

        [Parameter(Position = 0, ValueFromPipeline = $true)]
        #[ValidateSet('VMware.vSphere')]
        [ValidateScript( {
                $_ -match "$(((Get-ChesterProvider).Name) -join '|')"
            })]
        [System.String]$Provider,

        [Parameter(Position = 1)]
        [System.String]$EnvironmentName,

        [Parameter(Position = 2)]
        [ValidateSet('Fixture', 'AutoGenerate')]
        [System.String]$ConfigType = 'Fixure',

        [Parameter(Position = 3)]
        [System.String]$Path = "$Home\.chester",

        [Parameter(Position = 4, ValueFromPipeline = $true)]
        [System.String]$CreateConfigScript

    )

    BEGIN {

        $endpointFullName = $null
        $endpointFullName = $Provider + "." + $EnvironmentName.ToUpper()

        Write-Verbose -Message "[$($PSCmdlet.MyInvocation.MyCommand.Name)] Creating Endpoint { $endpointFullName }"

        if ($PSBoundParameters.Keys.Contains('CreateConfigScript')) {

            $configScript = $null
            $configScript = $CreateConfigScript

        } else {

            $configScript = $null
            $configScript = (Get-ChesterProvider -Name $Provider -ErrorAction 'SilentlyContinue').CreateConfigScript

        } # if/else

        if (Test-Path $configScript -PathType Leaf) {
            Write-Verbose -Message "[$($PSCmdlet.MyInvocation.MyCommand.Name)] Configuration Generation File Found for Provider { $Provider }; Continuing"
        } else {
            throw "[$($PSCmdlet.MyInvocation.MyCommand.Name)][ERROR] Could not resolve the Configuration Generation script for the Provider { $Provider }"
        } # if/else

    } # BEGIN

    PROCESS {

        # test for .chester directory
        if (-not (Test-Path -Path $Path -PathType Container)) {

            try {
                [void](New-Item -ItemType Directory -Path $Path -Force -ErrorAction 'Stop')
            } catch {
                throw "[$($PSCmdlet.MyInvocation.MyCommand.Name)] Could not create .Chester directory { $Path }. $_"
            } # end try/catch

        } # end if

        try {
            [void](New-Item -ItemType Directory -Path $Path\$endpointFullName -Force -ErrorAction 'Stop')
        } catch {
            throw "[$($PSCmdlet.MyInvocation.MyCommand.Name)][ERROR] Could not create Chester endpoint directory { $Path }. $_"
        } # try/catch


        try {

            $credSplat = $null
            $credSplat = @{
                Path        = "$Path\$endpointFullName\Authentication.clixml"
                Credential  = Get-Credential -Message "Enter the credentials for endpoint: $endpointFullName" -ErrorAction 'Stop'
                ErrorAction = 'stop'
            }

            Export-ChesterCredential @credSplat

        } catch {
            throw "[$($PSCmdlet.MyInvocation.MyCommand.Name)] Could not export Endpoint credential. $_"
        }


        switch ($ConfigType) {

            'Fixture' {

                $fixtureSplat = $null
                $fixtureSplat = @{
                    OutputFolder = "$Path\$endpointFullName"
                    ConfigType   = 'Fixture'
                    Provider     = $Provider
                }

                & $configScript @fixtureSplat

            } # Fixture


            'AutoGenerated' {

                $fixtureSplat = $null
                $fixtureSplat = @{
                    OutputFolder = "$Path\$endpointFullName"
                    ConfigType   = 'AutoGenerate'
                    Provider     = $Provider
                }

                & $configScript @fixtureSplat

            } # Autogenerated



        } # switch

    } # end PROCESS block

    END {

    }

} #function