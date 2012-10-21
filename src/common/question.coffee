# Utility question system used to get user input on a series of questions.

readline = require 'readline'
colors   = require 'colors'


# QuestionSystem is used to prompt the user
# a series of questions and then get a map
# back with the answers.
class QuestionSystem

    # Initializes the question system.
    #
    # * rl: (optional) the terminal interface to use.
    #       If null, a new one will be created.
    constructor: (@rl) ->
        @callback  = -> 0 # Dummy method
        @questions = []
        @answers   = {}

        # Initialize internal datatypes
        @qid  = 0
        @qraw = []


    # Sets the method to call on completion.
    #
    # * cb: The method to call. It will be called
    #       with an object on the form:
    #       { <group>: { <question>: <answer>, ... }, ... }
    setCallback: (cb) ->
        @callback = (cb ? -> 0)


    # Starts the questionnaire.
    #
    # * cb: (optional) Sets the callback.
    #       See #setCallback(cb) for more info.
    start: (cb) ->
        @callback ?= cb

        # Reset question index
        @qid = 0
        @lastGroup = ''

        unless @rl?
            # Initialize terminal interface
            @rl = readline.createInterface {
                input : process.stdin
                output: process.stdout
            }
        @ask()


    # Checks the input answer and moves on to the next question.
    checkAnswer: (line) ->
        line = line.trim()
        {group, name} = @getCurrent()
        @answers[group][name] = line

        @qid++
        @ask()


    # Asks the current question.
    ask: ->
        if @isCompleted()
            return @callback(@answers)

        {group, name, value} = @getCurrent()

        if group isnt @lastGroup
            # Print group header
            console.log " [#{@lastGroup = group}]".bold.blue
            @answers[group] = {}

        # Ask the question and insert default answer
        @rl.question " * #{name}: ", (answer) =>
            @checkAnswer answer
        @rl.write value
        

    # Returns whether the questionnaire is completed.
    isCompleted: ->
        return @qid >= @qraw.length


    # Returns the current question.
    getCurrent: ->
        return @qraw[@qid]


    # Removes all questions.
    clear: ->
        @questions = []
        @updateFlatQuestions()


    # Creates a new question.
    #
    # * groupName   : The question group to use.
    # * question    : The question name.
    # * defaultValue: (optional) the default value for the question.
    add: (groupName, question, defaultValue) ->
        group = @getGroup groupName

        group.fields.push {
            name : question
            value: defaultValue ? ''
        }
        @updateFlatQuestions()


    # Updates the internal question list.
    # Do not call this from outside the object.
    updateFlatQuestions: ->
        # @qraw is a flat version of the @questions array
        # used for simpler iteration.
        @qraw = []
        for group in @questions
            for question in group.fields
                @qraw.push {
                    group: group.group
                    name : question.name
                    value: question.value
                }


    # Finds a group.
    # This will create a new group if none is found.
    #
    # * groupName: The name of the group to find/create.
    # = returns the group object.
    getGroup: (groupName) ->
        # First see if a group with that name exists.
        for q in @questions
            return q if q.group is groupName

        # If it doesn't, create a new one and return it.
        @questions.push (q = {
            group : groupName
            fields: []
        })
        return q


exports.QuestionSystem = QuestionSystem
