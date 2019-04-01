# Copyright (c) 2019, Michael Wallio
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions 
# are met:
#   - Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
#   - Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in 
#     the documentation and/or other materials provided with the 
#     distribution.
#   - Neither the name of ScaryRawr nor the names of its 
#     contributors may be used to endorse or promote products derived 
#     from this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
# FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL 
# ScaryRawr BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT 
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF 
# USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, 
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT 
# OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF 
# SUCH DAMAGE.

Class AvailableLicenses : System.Management.Automation.IValidateSetValuesGenerator {
    [string[]] GetValidValues() {
        $directory = Split-Path -Path $PSCommandPath -Parent
        $dirLic = Join-Path -Path $directory "license_files"
        return (Get-ChildItem -Path $dirLic | ForEach-Object { $_.BaseName })
    }
}

<#
.Synopsis
Creates or updates a file with a license

.Description
Creates or updates a file with a license

.Parameter Path
Path to the file to create/add license to

.Parameter License
License to use for the file

.Parameter Author
The author's name

.Parameter Organization
The company/organization that the file belongs to
#>
function Add-License {
    param(
        [Parameter(Mandatory = $true)][string] $Path,
        [Parameter(Mandatory = $true)][ValidateSet([AvailableLicenses])][string] $License,
        [string] $Author,
        [string] $Organization
    )

    $directory = Split-Path -Path $PSCommandPath -Parent
    $cmd = Join-Path -Path $directory "addlicense.pl"
    $args = "-f `"$Path`" -l `"$License`""

    if ($Author) {
        $args += " -n `"$Author`""
    }

    if ($Organization) {
        $args += " -o `"$Organization`""
    }

    Invoke-Expression -Command "perl $cmd $args"
}