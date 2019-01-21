
function Solve-Sudoku
{

    param(
        [string]$Path = 'sudoku.txt',
        # How many answers to return?
        [int]$HowManyAnswersYouWanttoGet = 1,
        [switch]$debug
    )

    try
    {
        $SudokuMatrix = Get-Content -Path $Path
    }
    catch
    {
        Write-Host 'Please provide the sudoku text file'
        return
    }

    $SudokuMatrix = $SudokuMatrix | ?{$_ -notmatch '^#'}
    $SudokuMatrix = ($SudokuMatrix -join '') -ireplace '\s'

    $SudokuMatrix = [regex]::Matches($SudokuMatrix, '\d{81}')

    if(!$SudokuMatrix)
    {
        Write-Host "No enough numbers found in file: $Path"
        Write-Host 'At least 81 numbers?'
        return
    }

    $SudokuMatrixs = @()
    $SudokuMatrix | %{
        $SudokuMatrixs += $null
        $SudokuMatrixs[-1] = @()
        [regex]::Matches($_.Value, '\d{9}') | %{
            $SudokuMatrixs[-1] += $null
            $SudokuMatrixs[-1][-1] = @([regex]::Matches($_.Value, '\d') | %{[int]$_.Value})
        }
    }

    Write-Host "Sudokus in file count: $($SudokuMatrixs.Count)"
    function GoCalculate($arr){
        if(!$arr){return}

        # make a deep copy of array for assuming numbers
        $arr = [Management.Automation.PSSerializer]::DeSerialize([Management.Automation.PSSerializer]::Serialize($arr))

        # Filter out possible numbers for all elements
        RestrictPossibleNumbers2($arr)
        if($debug){debug($arr); $x = Read-Host}

        # verify the calculation is not a dead end!
        $NonOptionElement = Verify($arr)
        if($NonOptionElement[2]){return}

        # how many elements are confirmed
        $n_CellsConfirmed = CellsConfirmed($arr)
        if($n_CellsConfirmed -eq 81){ # 81 elements have been confirmed, one answer found
            $Script:AnswerCount++
            $Script:Results += $null
            $Script:Results[-1] = @($arr | %{@($_ | %{$_[0]}) -join ' '})
            return
        }

        # find the element that contains the least options of numbers
        $TheLeastOptionCell = FindTheLeast($arr)

        # make a copy of options
        $Options = [Management.Automation.PSSerializer]::DeSerialize([Management.Automation.PSSerializer]::Serialize($arr[$TheLeastOptionCell[0]][$TheLeastOptionCell[1]]))

        # assume options
        foreach($Option in $Options){
            $arr[$TheLeastOptionCell[0]][$TheLeastOptionCell[1]] = @($Option)
            # Assume an number to the element and fire a new caculation
            if($Script:AnswerCount -lt $HowManyAnswersYouWanttoGet){
                GoCalculate($arr)
            }
            else{return}
        }
    }

    # Loop each element, calculate possible number options for each element.
    function RestrictPossibleNumbers2($arr){
        for($i = 0; $i -lt 9; $i++)
        {
            for($j = 0; $j -lt 9; $j++)
            {
                if($arr[$i][$j].Count -ne 1)
                {
                    for($h = 0; $h -lt 9; $h++)
                    {
                        if($h -ne $i -and $arr[$h][$j].Count -eq 1)
                        {
                            $arr[$i][$j] = @($arr[$i][$j] | ?{$_ -ne $arr[$h][$j][0]})
                        }
                    }
                    for($v = 0; $v -lt 9; $v++)
                    {
                        if($v -ne $j -and $arr[$i][$v].Count -eq 1)
                        {
                            $arr[$i][$j] = @($arr[$i][$j] | ?{$_ -ne $arr[$i][$v][0]})
                        }
                    }
                    ###
                    $ni = [math]::Floor($i/3)
                    $nj = [math]::Floor($j/3)
                    for($mi = $ni * 3; $mi -lt (3 + $ni * 3); $mi++)
                    {
                        for($mj = $nj * 3; $mj -lt (3 + $nj * 3); $mj++)
                        {
                            if($mi -ne $i -and $mj -ne $j -and $arr[$mi][$mj].Count -eq 1)
                            {
                                $arr[$i][$j] = @($arr[$i][$j] | ?{$_ -ne $arr[$mi][$mj][0]})
                            }
                        }
                    }
                }
            }
        }
    }

    # Find the element with the least possibility of number options, return its position and count of number optinos
    function FindTheLeast($arr){
        foreach($k in 2..9){
            for($i = 0; $i -lt 9; $i++){
                for($j = 0; $j -lt 9; $j++){
                    if($arr[$i][$j].Count -eq $k){
                        return $i, $j, $k
                    }
                }
            }
        }
    }

    # debug output
    function debug($arr)
    {
        Write-Host "-------------------------"
        $arrx = [Management.Automation.PSSerializer]::DeSerialize([Management.Automation.PSSerializer]::Serialize($arr))
        for($a = 0; $a -lt $arrx.Count; $a++)
        {
            for($aa = 0; $aa -lt $arrx[$a].Count; $aa++)
            {
                if($arrx[$a][$aa].Count -gt 1)
                {
                    Write-Host $arrx[$a][$aa].Count -NoNewline -ForegroundColor Green
                }
                elseif($arrx[$a][$aa].Count -eq 1)
                {
                    Write-Host $arrx[$a][$aa][0] -NoNewline -ForegroundColor Yellow
                }
                else
                {
                    Write-Host 'X' -NoNewline -ForegroundColor Red
                }
                Write-Host ' ' -NoNewline
            }
            Write-Host "`n"
        }
        for($a = 0; $a -lt 3; $a++)
        {
            for($aa = 0; $aa -lt 3; $aa++)
            {
                Write-Host "[$a, $aa] Options count: $($arrx[$a][$aa].Count); Options: $($arrx[$a][$aa] -join ',')"
            }
        }
    }

    # Calculate how many elements have been confirmed, if it's 81, correct answer hit.
    function CellsConfirmed($arr){
        $Confirmed = 0
        for($i = 0; $i -lt 9; $i++){
            for($j = 0; $j -lt 9; $j++){
                if($arr[$i][$j] -and $arr[$i][$j].Count -eq 1){
                    $Confirmed++
                }
            }
        }
        return $Confirmed
    }

    # Loop each element, if the number options of any element is 0, means current calculation is a dead end.
    function Verify($arr){
        for($i = 0; $i -lt 9; $i++){
            for($j = 0; $j -lt 9; $j++){
                if($arr[$i][$j].Count -eq 0){
                    return $i, $j, $true # dead end, element in [$i, $j] has no available numbers
                }
            }
        }
        return $i, $j, $false # return false means all elements have available numbers
    }

    $n = 0
    foreach($SudokuMatrix in $SudokuMatrixs) # loop every sudoku found in sudoku file
    {
        $n++
        Write-Host "Processing sudoku: [$n]"
        # Loop each element, add array [1..9] for each every blank element.
        for($i = 0; $i -lt 9; $i++){
            for($j = 0; $j -lt 9; $j++){
                if($SudokuMatrix[$i][$j] -eq 0){
                    $SudokuMatrix[$i][$j] = @(1..9)
                }else{
                    $SudokuMatrix[$i][$j] = @($SudokuMatrix[$i][$j])
                }
            }
        }

        $Script:AnswerCount = 0
        $Script:Results = @()

        # Trigger
        GoCalculate($SudokuMatrix)

        # Output answers
        $Results | %{
            if($_ -eq $null){return}
            Write-Host 'Answer:' -ForegroundColor Yellow
            $_ -join "`n"
        }
    }

}

