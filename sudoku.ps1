
function Solve-Sudoku
{

    param(
        [string]$Path = 'sudoku.txt',
        # How many answers to return?
        [int]$HowManyAnswersYouWanttoGet = 1
    )

    try
    {
        $SudokuMatrix = Get-Content -Path $Path
    }
    catch
    {
        Write-Host 'Please provide sudoku text file'
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

    Write-Host "Sudoku in file found: $($SudokuMatrixs.Count)"

    function GoCalculate($arr){
        # update array to the latest
        GoLoop($arr)
        # verify the calculation is not a dead end!
        $ZeroPosition = Verify($arr)
        if($ZeroPosition[2]){
            # Write-Host "0 option found: [$($ZeroPosition[0])][$($ZeroPosition[1])]"
            return
        }
        # how many cells confirmed
        if((CellsConfirmed($arr)) -eq 81){
            $Script:AnswerCount++
            $Script:Results += $null
            $Script:Results[-1] = @($arr | %{@($_ | %{$_[0]}) -join ' '})
            return
        }
        # find the first cell with the leatest options
        $TheLeatestCell = FindTheLeatest($arr)
        $Options = @($arr[$TheLeatestCell[0]][$TheLeatestCell[1]]).PSObject.Copy()
        #Write-Host "Row: $($TheLeatestCell[0]); Col: $($TheLeatestCell[1]); Option: $($Options -join ' ')"
        foreach($Option in $Options){
            # Assume an option to the cell go a new loop
            $arr[$TheLeatestCell[0]][$TheLeatestCell[1]] = @($Option)
            if($AnswerCount -lt $HowManyAnswersYouWanttoGet){
                GoCalculate($arr)
            }
            else
            {return}
        }
    }

    # Loop each cell, calculate possible options and remove impossible options from cell.
    function GoLoop($arr){
        #$NewArr = @($null) * 9
        #for($i = 0; $i -lt 9; $i++){
        #    $NewArr[$i] = $arr[$i].PSObject.Copy()
        #}
        for($i = 0; $i -lt 9; $i++){
            for($j = 0; $j -lt 9; $j++){
                if($arr[$i][$j].Count -ne 1){
                    for($k = 0; $k -lt 9; $k++){
                        if($arr[$i][$k].Count -eq 1 -and $arr[$i][$j].Count -ne 1){
                            $arr[$i][$j] = @($arr[$i][$j] | ?{$_ -ne $arr[$i][$k][0]})
                        }
                        if($arr[$k][$j].Count -eq 1 -and $arr[$i][$j].Count -ne 1){
                            $arr[$i][$j] = @($arr[$i][$j] | ?{$_ -ne $arr[$k][$j][0]})
                        }
                    }
                }
            }
        }
        #return $NewArr
    }

    # Find the cell with the least number options, return its position and count of options
    function FindTheLeatest($arr){
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

    # Calculate how many cells have been confirmed, if it's 81, correct answer hit.
    function CellsConfirmed($arr){
        $Confirmed = 0
        for($i = 0; $i -lt 9; $i++){
            for($j = 0; $j -lt 9; $j++){
                if($arr[$i][$j].Count -eq 1){
                    $Confirmed++
                }
            }
        }
        return $Confirmed
    }

    # Loop each cell, if the number options of the cell is null, means current loop is a dead end.
    function Verify($arr){
        for($i = 0; $i -lt 9; $i++){
            for($j = 0; $j -lt 9; $j++){
                if($arr[$i][$j].Count -eq 0){
                    return $i, $j, $true # dead end
                }
            }
        }
        return $i, $j, $false
    }

    $n = 0
    foreach($SudokuMatrix in $SudokuMatrixs)
    {
        $n++
        Write-Host "Processing sudoku: [$n]"
        # Loop each cell, add array [1..9] for each null cell.
        for($i = 0; $i -lt 9; $i++){
            for($j = 0; $j -lt 9; $j++){
                if(!$SudokuMatrix[$i][$j]){
                    $SudokuMatrix[$i][$j] = 1..9
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
