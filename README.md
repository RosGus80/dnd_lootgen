Rule-based dnd loot gen engine
Should be able to generate both random loot findings and traders assortment based on survival/charisma rolls

engine.nim is core - functions that take all filters and everything as args and return loot
main-cli is for cli version, main-api is for web version (ill create a nuxt frontend maybe)

Uses https://github.com/5e-bits db and https://github.com/c-blake/cligen for command line interface generation