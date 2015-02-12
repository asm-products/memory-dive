
    expect = (require 'chai').expect
    _ = require 'lodash'
    render = (require '../../app/common/itemRenderer').render
    w3c = (require 'w3c-validate').createValidator()

    HOUR_IN_MILLISECONDS = 60 * 60 * 1000
    FIVE_MINUTES_IN_MILLISECONDS = 5 * 60 * 1000

    describe 'itemRenderer module', ->
        it 'renders as HTML undefined input', ->
            expect(render()).to.equal '<h5>Unknown item (model unknown, ID unknown)</h5><h6>00:00:00</h6>'

        it 'renders as HTML empty input', ->
            expect(render('')).to.equal '<h5>Unknown item (model unknown, ID unknown)</h5><h6>00:00:00</h6>'

        it 'renders as HTML incomplete input', ->
            expect(render({
                modelId: 12345,
                createdTime: FIVE_MINUTES_IN_MILLISECONDS,
                utcOffset: HOUR_IN_MILLISECONDS
            })).to.equal '<h5>Unknown item (model unknown, ID 12345)</h5><h6>01:05:00</h6>'

        it 'renders as HTML unrecognized input', ->
            expect(render({
                modelId: 12345,
                createdTime: FIVE_MINUTES_IN_MILLISECONDS,
                utcOffset: HOUR_IN_MILLISECONDS,
                model: 'UnknownObject'
            })).to.equal '<h5>Unknown item (model UnknownObject, ID 12345)</h5><h6>01:05:00</h6>'

        describe 'renders FacebookObject', ->
            it 'even when unknown type', ->
                expect(render({
                    modelId: 12345
                    createdTime: FIVE_MINUTES_IN_MILLISECONDS
                    utcOffset: HOUR_IN_MILLISECONDS
                    model: 'FacebookObject'
                    type: 'made-up'}))
                .to.equal '<h5>Invalid object (model FacebookObject, ID 12345, details type made-up)</h5><h6>01:05:00</h6>'

            it 'photo type on incomplete input', ->
                expect(render({
                    modelId: 12345
                    createdTime: FIVE_MINUTES_IN_MILLISECONDS
                    utcOffset: HOUR_IN_MILLISECONDS
                    model: 'FacebookObject'
                    type: 'photo' }))
                .to.equal '<h5>Invalid object (model FacebookObject, ID 12345, details type photo)</h5><h6>01:05:00</h6>'

            it 'photo type on complete input', ->
                expect(render({
                    modelId: 12345
                    createdTime: FIVE_MINUTES_IN_MILLISECONDS
                    utcOffset: HOUR_IN_MILLISECONDS
                    model: 'FacebookObject'
                    type: 'photo'
                    source: 'someimagesomewhere' }))
                .to.equal '<img src="someimagesomewhere" class="img-responsive"/><h6>01:05:00</h6>'

            it 'video type on incomplete input', ->
                expect(render({
                    modelId: 12345
                    createdTime: FIVE_MINUTES_IN_MILLISECONDS
                    utcOffset: HOUR_IN_MILLISECONDS
                    model: 'FacebookObject'
                    type: 'video' }))
                .to.equal '<h5>Invalid object (model FacebookObject, ID 12345, details type video)</h5><h6>01:05:00</h6>'

            it 'video type on complete input', ->
                expect(render({
                    modelId: 12345
                    createdTime: FIVE_MINUTES_IN_MILLISECONDS
                    utcOffset: HOUR_IN_MILLISECONDS
                    model: 'FacebookObject'
                    type: 'video'
                    extra:
                        embedHtml: '<img src="test"/>' }))
                .to.equal '<div><img src=\"test\"/></div><h6>01:05:00</h6>'

            it 'post type on incomplete input', ->
                expect(render({
                    modelId: 12345
                    createdTime: FIVE_MINUTES_IN_MILLISECONDS
                    utcOffset: HOUR_IN_MILLISECONDS
                    model: 'FacebookObject'
                    type: 'post' }))
                .to.equal '<h5>Invalid object (model FacebookObject, ID 12345, details type post.undefined)</h5><h6>01:05:00</h6>'

            it 'post.link type on complete input', ->
                expect(render({
                    modelId: 12345
                    createdTime: FIVE_MINUTES_IN_MILLISECONDS
                    utcOffset: HOUR_IN_MILLISECONDS
                    model: 'FacebookObject'
                    type: 'post'
                    extra:
                        type: 'link'
                        link: 'http://memorydive.io'
                        message: 'memorydive.io'
                    picture: 'whatever' }))
                .to.equal '<h5><a href=\"http://memorydive.io\" target=\"_blank\"><img src=\"whatever\"/></a>memorydive.io</h5><h6>01:05:00</h6>'

            it 'post.status type on complete input', ->
                expect(render({
                    modelId: 12345
                    createdTime: FIVE_MINUTES_IN_MILLISECONDS
                    utcOffset: HOUR_IN_MILLISECONDS
                    model: 'FacebookObject'
                    type: 'post'
                    extra:
                        type: 'status'
                        message: 'whatever' }))
                .to.equal '<h5>whatever</h5><h6>01:05:00</h6>'

            it 'post.status type on complete input', ->
                expect(render({
                    modelId: 12345
                    createdTime: FIVE_MINUTES_IN_MILLISECONDS
                    utcOffset: HOUR_IN_MILLISECONDS
                    model: 'FacebookObject'
                    type: 'post'
                    extra:
                        type: 'status'
                        story: 'whatever' }))
                .to.equal '<h5>whatever</h5><h6>01:05:00</h6>'

        describe 'renders TwitterObject', ->
            it 'even when unknown type', ->
                expect(render({
                    modelId: 12345
                    createdTime: FIVE_MINUTES_IN_MILLISECONDS
                    utcOffset: HOUR_IN_MILLISECONDS
                    model: 'TwitterObject'
                    type: 'made-up'}))
                .to.equal '<h5>Invalid object (model TwitterObject, ID 12345, details made-up)</h5><h6>01:05:00</h6>'

            it 'status type on incomplete input', ->
                expect(render({
                    modelId: 12345
                    createdTime: FIVE_MINUTES_IN_MILLISECONDS
                    utcOffset: HOUR_IN_MILLISECONDS
                    model: 'TwitterObject'
                    type: 'status' }))
                .to.equal '<h5>Invalid object (model TwitterObject, ID 12345, details status)</h5><h6>01:05:00</h6>'

            it 'status type on complete input', ->
                expect(render({
                    modelId: 12345
                    createdTime: FIVE_MINUTES_IN_MILLISECONDS
                    utcOffset: HOUR_IN_MILLISECONDS
                    model: 'TwitterObject'
                    type: 'status'
                    text: 'hey' }))
                .to.equal '<h5>hey</h5><h6>01:05:00</h6>'

            it 'status type on complete input for retweets', ->
                expect(render({
                    modelId: 12345
                    createdTime: FIVE_MINUTES_IN_MILLISECONDS
                    utcOffset: HOUR_IN_MILLISECONDS
                    model: 'TwitterObject'
                    type: 'status'
                    text: 'retweeting'
                    extra:
                        retweeted: true
                        by: 'whatever'}))
                .to.equal '<h5>RT <a href=\"https://twitter.com/whatever\" target=\"_blank\">@whatever</a>: retweeting</h5><h6>01:05:00</h6>'

            it 'status type with URLs', ->
                expect(render({
                    modelId: 12345
                    createdTime: FIVE_MINUTES_IN_MILLISECONDS
                    utcOffset: HOUR_IN_MILLISECONDS
                    model: 'TwitterObject'
                    type: 'status'
                    text: 'this http://url.com is a well-formed URL'}))
                .to.equal '<h5>this <a href="http://url.com" target="_blank">http://url.com</a> is a well-formed URL</h5><h6>01:05:00</h6>'

        describe 'renders DropboxObject', ->
            it 'on incomplete input', ->
                expect(render({
                    modelId: 12345
                    createdTime: FIVE_MINUTES_IN_MILLISECONDS
                    utcOffset: HOUR_IN_MILLISECONDS
                    model: 'DropboxObject' }))
                .to.equal '<h5>Invalid object (model DropboxObject, ID 12345, details )</h5><h6>01:05:00</h6>'

            it 'on complete input', ->
                expect(render({
                    modelId: 12345
                    createdTime: FIVE_MINUTES_IN_MILLISECONDS
                    utcOffset: HOUR_IN_MILLISECONDS
                    model: 'DropboxObject'
                    path: 'some-path' }))
                .to.equal '<img id=\"dropbox-some-path\"/><h6>01:05:00</h6>'

        describe 'renders EvernoteObject', ->
            it 'on complete input', ->
                expect(render({
                    modelId: 12345
                    createdTime: FIVE_MINUTES_IN_MILLISECONDS
                    utcOffset: HOUR_IN_MILLISECONDS
                    model: 'EvernoteObject' }))
                .to.equal '<h5>Unknown item (model EvernoteObject, ID 12345)</h5><h6>01:05:00</h6>'
