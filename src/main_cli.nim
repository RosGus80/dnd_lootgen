import ./engine
import strutils, os, json


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
            var newPath = baseDir / "db" / customFolderName / fileName

            if fileExists(newPath):
                let (dir, name, ext) = splitFile(newPath)
                var i: uint
                while true:
                    i += 1
                    let candidate = dir & name & "_" & $i & ext

                    if not fileExists(candidate):
                        newPath = candidate
                        break

            createDir(baseDir / "db" / customFolderName)

            copyFile(filePath, newPath)

            echo "File copied successfully"
        else:
            raise newException(ValueError, "File must be of json extention")


proc addItem(fileName: string, customFolderName: string) = 
    let baseDir = getCurrentDir()

    let fileName: string = 
        if fileName.endsWith(".json"):
            fileName
        else:
            fileName & ".json"

    let fullPath = baseDir / "db" / customFolderName / fileName 

    echo "Enter item name: "
    stdout.write("> ")

    var itemName: string
    while true:
        itemName = stdin.readline()
        if itemName.len > 0: break
    
    echo "Enter item description: "
    stdout.write("> ")

    var itemDescription: string
    while true:
        itemDescription = stdin.readline()
        if itemDescription.len > 0: break

    echo "Enter item possible locatios (only the corresponding numbers), separated by space OR write your custom location name (must not contain spaces. Recommend using - symbol as an alternative): "
    
    let allItems = getAllItems(@[customFolderName])
    let allLocations = getAllLocations(allItems)

    for i, location in allLocations:
        echo $i & ". " & location

    stdout.write("> ")

    var itemLocations: seq[Location]

    let locationInput = stdin.readline()

    for loc in locationInput.split(" "):
        try:
            let location: Location = allLocations[loc.parseInt()]

            itemLocations.add(location)
        except ValueError:
            # ? If not a number
            echo "Add " & loc & " as a custom location? y/yes for yes, all other inputs for no"

            stdout.write("> ")
            let input = stdin.readline()

            if input in ["y", "yes"]:
                itemLocations.add(loc)
            else:
                continue
        except IndexDefect:
            # ? If a number is not in the list but is a number
            echo $loc & " is not a valid index. Skipping."


    var itemRarity: Rarity

    while true:
        echo "Input item's rarity"

        var i: uint
        while true:
            try:
                echo $i & ". " &  $Rarity(i)
                i += 1  
            except RangeDefect:
                break

        let rarityInput = stdin.readline()

        try:
            itemRarity = Rarity(rarityInput.parseuint())

            break
        except RangeDefect, ValueError:
            echo "Not a valid index"


    var itemPrice: float

    while true:
        echo "Input item price (a number, possibly with a floating point)"
        stdout.write("> ")

        try:
            itemPrice = stdin.readline().parseFloat()
            break
        except ValueError:
            echo "It is not a valid price. Please, input a number"

    let newItem: Item = Item(
            name: itemName,
            description: itemDescription,
            gpCost: itemPrice,
            rarity: itemRarity,
            locations: itemLocations
        )

    
    let jsonNode = loadJsonArray(fullPath)
    jsonNode.add(%newItem)

    writeFile(fullPath, pretty(jsonNode))

    echo itemName & " added successfully!"

        


        
when isMainModule:
    import cligen
    dispatchMulti([loot], [addFile], [addItem])

