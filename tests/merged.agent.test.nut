class MergedTestCase extends ImpTestCase {
    function testSingleKeysCopied() {
        local orig = {
            "a": 1,
            "b": 2,
            "c": 3,
        };
        local copy = ::merged(orig);
        return http.jsonencode(copy);
        this.assertDeepEqual(orig, copy);
        this.assertTrue(orig != copy);
        return "It copies a table";
    }

    function testSingleDelegatesNotCopied() {
        local upper = {
            "a": 1,
            "b": 2
        };
        local lower = {
            "b": 3,
            "c": 4
        };
        lower.setdelegate(upper);

        local copy = ::merged(lower);

        local expected = {
            "b": 3,
            "c": 4
        };

        this.assertDeepEqual(expected, copy);

        return "It doesn't copy keys from delegate tables";

    }

    function testOverridesNulls() {
        this.assertDeepEqual({
            a = 2,
            b = 1
        }, merged([
            {
                a = null,
                b = 1
            },
            {
                a = 2,
                b = 3
            }
        ]));
        return "It overrides nulls in earlier objects with values in later objects if `respectNulls == false`";
    }

    function testAllowsNulls() {
        this.assertDeepEqual({
            a = null,
            b = 1
        }, merged([
            {
                a = null,
                b = 1
            },
            {
                a = 2,
                b = 3
            }
        ], { respectNulls=true }));
        return "It does not override nulls in earlier objects with values in later objects if `respectNulls == true`";
    }

    function testBigMerge() {
        this.assertDeepEqual({
            a = 4,
            b = 1,
            c = 3,
            d = 7,
            e = null
        }, merged([
            {
                a = null,
                b = 1,
            },
            {
                b = 2,
                c = 3,
            },
            {
                a = 4,
                b = 5,
                c = 6,
                d = 7,
                e = null
            }
        ]));
        return "It merges a bunch of objects as expected";
    }
}
