
    expect = (require 'chai').expect
    _ = require 'lodash'

    compound = null
    collector = null

    describe 'readabilityCollector module', ->
        this.timeout 60000

        before (done) ->
            compound = getCompound()
            expect(compound).to.exist
            if compound.memoryDiveReady
                return init done
            compound.on 'memoryDiveReady', ->
                return init done

        init = (done) ->
            collector = compound.collectors.readability
            expect(collector).to.exist
            done()

        describe 'has collectWebPages that', ->
            it 'throw if no callback is given', ->
                expect(collector.collectWebPage).to.throw

            it 'collects web pages', (done) ->

                nocks = compound.startNocking 'workers__data__readabilityCollector.1.json'

                counter = 0
                collector.collectWebPages ['http://bit.ly/1hKHiTe'], (err, item, next) ->
                    return done err if err

                    if item
                        ++counter

                        expect(item).to.be.ok
                        expect(item.url).to.equal 'http://arstechnica.com/apple/2013/10/os-x-10-9/'
                        expect(item.contentType).to.equal 'text/html; charset=UTF-8'
                        expect(item.title).to.equal 'OS X 10.9 Mavericks: The Ars Technica Review'
                        expect(item.html).to.be.ok
                        expect(item.language).to.equal 'english'

                        return next()

                    expectAll()

                expectAll = () ->
                    expect(counter).to.equal 1
                    compound.stopNocking nocks
                    done()
