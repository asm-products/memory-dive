
    chai = require 'chai'
    expect = chai.expect

    compound = null
    hellRaiser = null
    constants = null
    error = null

    describe 'hellRaiser module', ->
        this.timeout 15000
        
        before (done) ->
            compound = getCompound()
            expect(compound).to.exist
            if compound.memoryDiveReady
                return init done
            compound.on 'memoryDiveReady', ->
                return init done

        init = (done) ->
            hellRaiser = compound.common.hellRaiser
            expect(hellRaiser).to.exist
            error = compound.common.constants.error
            expect(error).to.exist
            done()

        describe 'has raise function that', ->
            it 'throws exceptions when no callback', ->
                try
                    hellRaiser.raise
                catch ex
                    expect(ex).to.exist
                    expect(ex.message).to.be.undefined
                    expect(ex.code).to.equal 0

                try
                    hellRaiser.raise 'test'
                catch ex
                    expect(ex).to.exist
                    expect(ex.message).to.equal 'test'
                    expect(ex.code).to.be.undefined

                try
                    hellRaiser.raise 'test', 123
                catch ex
                    expect(ex).to.exist
                    expect(ex.message).to.equal 'test'
                    expect(ex.code).to.equal 123

            it 'invokes callback when it is defined', (done) ->
                hellRaiser.raise 'test', 123, (err) ->
                    expect(err).to.exist
                    expect(err.message).to.equal 'test'
                    expect(err.code).to.equal 123
                    done()

        describe 'has specialized functions for common errors', ->
            it 'userNotFound raises USER_NOT_FOUND', (done) ->
                hellRaiser.userNotFound 123, (err) ->
                    expect(err).to.exist
                    expect(err.message).to.equal 'User 123 not found'
                    expect(err.code).to.equal error.USER_NOT_FOUND
                    done()

            it 'invalidArgs raises INVALID_ARGS for no params', (done) ->
                hellRaiser.invalidArgs undefined, (err) ->
                    expect(err).to.exist
                    expect(err.message).to.equal 'no arguments'
                    expect(err.code).to.equal error.INVALID_ARGS
                    done()

            it 'invalidArgs raises INVALID_ARGS for bad params', (done) ->
                hellRaiser.invalidArgs 'bad', (err) ->
                    expect(err).to.exist
                    expect(err.message).to.equal 'no arguments'
                    expect(err.code).to.equal error.INVALID_ARGS
                    done()

            it 'invalidArgs raises INVALID_ARGS for empty params', (done) ->
                hellRaiser.invalidArgs [], (err) ->
                    expect(err).to.exist
                    expect(err.message).to.equal 'no arguments'
                    expect(err.code).to.equal error.INVALID_ARGS
                    done()

            it 'invalidArgs raises INVALID_ARGS for other params', (done) ->
                hellRaiser.invalidArgs [1, { two: 2 }, '3'], (err) ->
                    expect(err).to.exist
                    expect(err.message).to.equal '1, [object Object], 3'
                    expect(err.code).to.equal error.INVALID_ARGS
                    done()
