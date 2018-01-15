
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
        # update array to the latest
        GoLoop($arr)
        # verify the calculation is not a dead end!
        $ZeroPosition = Verify($arr)
        if($ZeroPosition[2]){
            # Write-Host "0 option found: [$($ZeroPosition[0])][$($ZeroPosition[1])]"
            return
        }
        # how many cells confirmed
        $n_CellsConfirmed = CellsConfirmed($arr)
        if($n_CellsConfirmed -eq 81){ # 81 elements have been confirmed, one answer found
            $Script:AnswerCount++
            $Script:Results += $null
            $Script:Results[-1] = @($arr | %{@($_ | %{$_[0]}) -join ' '})
            return
        }
        # find the element that contains the least possibility of numbers
        $TheLeastCell = FindTheLeast($arr)
        $Options = @($arr[$TheLeastCell[0]][$TheLeastCell[1]]).PSObject.Copy()
        #Write-Host "Row: $($TheLeastCell[0]); Col: $($TheLeastCell[1]); Option: $($Options -join ' ')"
        foreach($Option in $Options){
            # Assume an number to the element and fire a new caculation
            $arr[$TheLeastCell[0]][$TheLeastCell[1]] = @($Option)
            if($AnswerCount -lt $HowManyAnswersYouWanttoGet){
                GoCalculate($arr)
            }
            else
            {return}
        }
    }

    # Loop each element, calculate possible number options for each element.
    function GoLoop($arr){
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
