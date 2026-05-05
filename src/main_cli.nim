import ./engine
import strutils, os


func getAllLocations(items: seq[Item]): seq[Location] = 
    result.add("all")

    for item in items:
        let itemLocations: seq[Location] = item.locations

        for location in itemLocations:
            if not (location in result):
                result.add(location)


proc loot(            
        roll: uint, 
        isNatTwenty: bool = false, 
        itemsAmount: uint = 0,
        additionalFolders: seq[string] = @[]
    ) =

    let allItems: seq[Item] = getAllItems(additionalFolders)
    let allLocations: seq[Location] = getAllLocations(allItems)

    echo "Where is the company? (input a number)"
    for i, loc in allLocations:
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


proc addFile(filePath: string, customFolderName: string) = 
    # ? Adds a file to the db/folder folder so that user can create separate folders 
    # ? for different settings he'd want to use.

    let info = getFileInfo(filePath)

    if info.kind == pcFile:
        if filePath.endsWith(".json"):
            let baseDir = getCurrentDir()

            let fileName = extractFilename(filePath)
            let newPath = baseDir / "db" / customFolderName / fileName

            createDir(baseDir / "db" / customFolderName)

            copyFile(filePath, newPath)

            echo "File copied successfully"
        else:
            raise newException(ValueError, "File must be of json extention")



        


import cligen
dispatchMulti([loot], [addFile])

