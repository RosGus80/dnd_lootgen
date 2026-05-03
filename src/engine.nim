import options, json, os, strutils, sequtils, random, math

type 
    Location* = string 

    Rarity* = enum
        Common, Uncommon, Rare, Epic, Legendary

    Item* = object
        id: Option[uint]
        name: string
        description: string
        gpCost: float
        rarity: Rarity
        locations: seq[Location]

proc `$`*(i: Item): string =
  result =
    "╔══════════════════════════════╗\n" &
    "║ " & i.name & "\n" &
    "╠══════════════════════════════╣\n" &
    "║ " & i.description & "\n" &
    "║                              \n" &
    "║ Rarity: " & $i.rarity & "\n" &
    "║ GP: " & $i.gpCost & "\n" &
    "╚══════════════════════════════╝"


#[ Known locations - will only be used for the manual location input. 
    Planning to derive all available locations in frontend via the all relevant json's search and 
    getting all unique "location" fields ]#
const allLocationsSeq*: seq[Location] = @[
    "all",
    "town",
    "city",
    "village",
    "forest",
    "desert",
    "mountain",
    "plains",
    "swamp",
    "coast",
    "underwater",
    "dungeon",
    "ruins",
    "cave",
    "underdark"
]

func rarityFromPrice*(price: int): Rarity =
    # * Based on gp price
    if price <= 50: Common
    elif price < 500: Uncommon
    elif price <= 2500: Rare
    elif price <= 50000: Epic
    else: Legendary


proc loadJsonArray*(path: string): JsonNode =
    if fileExists(path):
        return parseJson(readFile(path))
    else:
        return newJArray()


proc getJsonFiles*(dir: string): seq[string] =
    for kind, path in walkDir(dir):
        if kind == pcFile and path.endsWith(".json"):
            result.add(path)


proc getItemsFromJson*(jsonFile: JsonNode): seq[Item] = 
    for node in jsonFile:
        try: 
            result.add(
                Item(
                    name: node["name"].getStr,
                    description: node["description"].getStr,
                    gpCost: node["gpCost"].getFloat,
                    rarity: parseEnum[Rarity](node["rarity"].getStr),
                    locations: node["locations"].to(seq[Location])
                )
            )
        except ValueError:
            continue

    
proc filterItemsByLoc*(items: seq[Item], locationTag: Location): seq[Item] = 
    for item in items:
        if "all" in item.locations or locationTag in item.locations:
            result.add(item)


proc getAllItems*(additionalFolders: seq[string]): seq[Item] = 
    var allFiles: seq[string] = getJsonFiles("db/core")
    
    for folder in additionalFolders:
        allFiles = allFiles & getJsonFiles("db/" & folder)

    var allItems: seq[Item] = @[]

    for file in allFiles:
        allItems = allItems & getItemsFromJson(file.loadJsonArray())

    return allItems


proc biasFromRoll(roll: uint): float =
    # ^ 0.0 .. 1.0
    # ? We get the point of our weight array where we want to pull the weight up
    # ? f(x) = 1/(1+e^(-k(x-m)))

    # Can modify these to change the way it behaves 
    let k = 0.3 # slope
    let m = 13.5 # f(m) = 0.5

    result = 1.0 / (1.0 + exp(-k * (float(roll) - m)))


proc gaussPull*(baseWeights: array[5, float], bias: float, sigma: float, alpha: float): seq[float] =
    # ? Sigma as a parameter regulates the sharpness of the pull
    # ? Alpha as a parameter regulates the strength with which center pulls values from other places

    let n = baseWeights.len
    result = newSeq[float](n)

    let center = bias * float(n - 1)
    let twoSigmaSq = 2.0 * sigma * sigma

    var sum = 0.0

    for i in 0..<n:
        let dist = float(i) - center
        let g = exp(-(dist * dist) / twoSigmaSq)

        result[i] = baseWeights[i] * (1.0 + alpha * g)
        sum += result[i]

    # normalise
    if sum > 0:
        for i in 0..<n:
            result[i] /= sum


proc getWeights*(roll: uint): seq[float] = 
    randomize()

    # ? Weights for getting an item of each rarity in order (idx = rarity enum)
    let baseWeights: array[5, float] = [45.0, 25.0, 15.0, 10.0, 5.0] # ! Same len as len of Rarity enum

    let bias = biasFromRoll(roll)
    echo "Bias: " & $bias

    # & Alpha and sigma here are arbitrary - tune for liking
    result = gaussPull(baseWeights, bias, 1.0, 2.0)


proc weightedIndex(weights: seq[float]): int =
    let r = rand(1.0) 

    var cumulative = 0.0
    for i, w in weights:
        cumulative += w
        if r < cumulative:
            return i

    # Fallback
    let maxVal = max(weights)

    for idx, val in weights:
        if val == maxVal:
            return idx 


proc rollItem(allItems: seq[Item], weights: seq[float]): Item = 
    if allItems.len == 0:
        raise newException(ValueError, "Empty allItems in rollItem!")

    let selectedRarity = Rarity(weightedIndex(weights))

    let pool: seq[Item] = allItems.filterIt(it.rarity == selectedRarity)

    if pool.len == 0:
        return allItems[rand(allItems.len - 1)]

    return pool[rand(pool.len - 1)]


proc genLoot*(
            roll: uint, 
            isNatTwenty: bool, 
            loc: Location = "all", 
            allItems: seq[Item], 
            itemsAmount: uint = 0
        ): seq[Item] =

    # ? Gets a roll (summed with ability mod), location, takes all relevant json files and generate loot
    randomize()
    
    let itemsInLocation: seq[Item] = allItems.filterItemsByLoc(loc)

    var finalItems: seq[Item] = @[]
    let amount =
        if itemsAmount == 0:
            uint(rand(1..8))
        else:
            itemsAmount

    let weights = getWeights(roll)

    echo weights

    for i in 0..amount-1:
        let newItem: Item = rollItem(itemsInLocation, weights)
        finalItems.add(newItem)

    return finalItems


proc genTrader*(
        charismaRoll: uint,
        loc: Location = "all",
        allItems: seq[Item],
        itemsAmount: uint = 0
    ): seq[Item] =
    # TODO

    


    