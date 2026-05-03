import ./engine
import strutils

proc loot(            
        roll: uint, 
        isNatTwenty: bool = false, 
        itemsAmount: uint = 0,
        additionalFolders: seq[string] = @[]
    ) =

    echo "Where is the company? (input a number)"
    for i, loc in allLocationsSeq:
        if loc == "all":
            echo $i & " " & "Default"
        else:
            echo $i & " " & loc.capitalizeAscii()

    var loc: string
    try:
        stdout.write("> ")
        loc = readline(stdin)
    except ValueError:
        echo "Didn't get a valid input, defaulting to 'all'"
        loc = "all"
    

    while true:
        let items: seq[Item] = genLoot(
            roll,
            isNatTwenty,
            loc,
            getAllItems(
                additionalFolders
            ),
            itemsAmount,
        )

        for item in items:
            echo $item

        echo "--------- Generate again? (y for yes, all other inputs for no) ---------"

        if readline(stdin) != "y":
            break


    

import cligen; dispatch loot

