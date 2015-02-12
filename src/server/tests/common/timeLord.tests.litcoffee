
    expect = (require 'chai').expect
    _ = require 'lodash'

Lord is my cat.

    lord = (require '../../app/common/timeLord')

    describe 'timeLord module', ->
        describe 'offset function', ->
            it 'gives undefined on bad timezone', ->
                offset = lord.offset('Baaad/Continental', 0)
                expect(offset).to.be.undefined

            it 'gives correct offset value', ->
                offset = lord.offset('Chile/Continental', 0)
                expect(offset).to.be.ok
                expect(offset).to.equal -3 * 60 * 60 * 1000

            it 'gives correct offset value', ->
                offset = lord.offset('America/Santiago', new Date(2011, 7, 11))
                expect(offset).to.be.ok
                expect(offset).to.equal -4 * 60 * 60 * 1000

            it 'gives correct offset value when epoch is not specified', ->
                offset = lord.offset('America/Santiago')
                expect(offset).to.be.ok
                expect(offset).to.equal -3 * 60 * 60 * 1000
