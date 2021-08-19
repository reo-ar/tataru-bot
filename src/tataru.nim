import dimscord
import dimscmd
import dimscmd/interactionUtils
import asyncdispatch
import strutils
import options
import strscans
import strformat
import httpclient
import json

echo("Tataru is loading!")

const token = ""

let discord = newDiscordClient(token)
let client = newAsyncHttpClient()
var cmd = discord.newHandler()

proc interactionCreate (s: Shard, i: Interaction) {.event(discord).} =
    discard await cmd.handleInteraction(s, i)

cmd.addSlash("plus", guildID = "793423658433249322") do (a: int, b: int):
    ## Adds two numbers!
    let response = InteractionResponse(
        kind: irtChannelMessageWithSource,
        data: some InteractionApplicationCommandCallbackData(
            embeds: @[Embed(
                title: some("Tataru"), 
                description: some("Adding!"),
                fields: some(@[EmbedField(
                    name: "test",
                    value: fmt"{a} + {b} = {a + b}"
                )])
            )]
        )
    )
    await discord.api.createInteractionResponse(i.id, i.token, response)

cmd.addSlash("profile", guildID = "793423658433249322") do (server: string, firstname: string, surname: string):
    ## Grabs FFXIV basic details, Still unfinished and possibly broken, Grabs your character info
    await discord.api.createInteractionResponse(i.id, i.token, 
        InteractionResponse(
            kind: irtDeferredChannelMessageWithSource
        )
    )

    var
        search_url = fmt"https://xivapi.com/character/search?name={firstname.strip()}%20{surname.strip()}&server={server.strip()}"
        search_content = waitFor client.getContent(search_url)
        search_parsed_json = search_content.parseJson()
        results = search_parsed_json["Results"]
        first_result = results{0}

    var embed: Embed

    if first_result.isNil:
        embed = Embed(
            title: some("ERROR!"),
            description: some("Character/Server not found!"),
        )

    else:
        var
            user_id = first_result["ID"]
            profile_url = fmt"https://xivapi.com/character/{user_id}"
            content = waitFor client.getContent(profile_url)
            parsed_json = content.parseJson()
            character = parsed_json["Character"]
            active_class_job = character["ActiveClassJob"]
            unlocked_state = active_class_job["UnlockedState"]
            char_name = character["Name"].getStr()
            portrait_url = character["Portrait"].getStr()
            level = active_class_job["Level"].getInt()
            job_name = unlocked_state["Name"].getStr()
            desc_string = fmt"***Level {level}, {job_name}***"

        embed = Embed(
            title: some(char_name),
            description: some(desc_string),
            image: some(EmbedImage(url: some(portrait_url)))
        )

    await discord.api.editWebhookMessage(s.user.id, i.token, "@original", embeds = @[embed])

discord.events.on_ready = proc (s: Shard, r: Ready) {.async.} =
    echo "Ready as " & $r.user
    await cmd.registerCommands()
    echo "Registered Slash Commands!!"

waitFor discord.startSession()