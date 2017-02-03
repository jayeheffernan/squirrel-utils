class CopyTestCase extends ImpTestCase {
    function testKeysCopied() {
        local orig = {
            "a": 1,
            "b": 2,
            "c": 3,
        };
        local copy = ::copy(orig);
        this.assertDeepEqual(orig, copy);
        this.assertTrue(orig != copy);
    }

    function testDelegatesNotCopied() {
        local upper = {
            "a": 1,
            "b": 2
        };
        local lower = {
            "b": 3,
            "c": 4
        };
        lower.setdelegate(upper);

        local copy = ::copy(lower);

        local expected = {
            "b": 3,
            "c": 4
        };

        this.assertDeepEqual(expected, copy);

    }
}
