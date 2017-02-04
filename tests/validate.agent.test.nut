class ValidateTestCase extends ImpTestCase {
    function test00() {
        // name: testSimpleValidation1
        local opts = {
            "a": 1
        };

        local err = validate(opts, [
            @() a==1
        ], { throws=false });

        this.assertEqual(null, err);

        return "It validates a simple, valid table with scope as parameter";
    }

    function test01() {
        // name: testSimpleValidation2
        local opts = {
            "a": 1
        };

        local err = validate([
            @() a==1
        ], { throws=false, scope=opts });

        this.assertEqual(null, err);

        return "It validates a simple, valid table with scope as option";
    }

    function test02() {
        // name: testSimpleValidation3
        local opts = {
            "a": 1
        };

        local err = validate([
            @() opts.a==1
        ], { throws=false });

        this.assertEqual(null, err);

        return "It validates a simple, valid table with no/automatic/default scope";
    }

    function test03() {
        // name: testSimpleValidationFail1
        local opts = {
            "a": 2
        };

        local err = validate(opts, [
            @() a==1 || "ERRMSG"
        ], { throws=false });

        this.assertTrue(regexp(".*ERRMSG$").match(err));

        return "It invalidates a simple, valid table with scope as parameter";
    }

    function test04() {
        // name: testSimpleValidationFail2
        local opts = {
            "a": 2
        };

        local err = validate([
            @() a==1 || "ERRMSG"
        ], { throws=false, scope=opts });

        this.assertTrue(regexp(".*ERRMSG$").match(err));

        return "It invalidates a simple, valid table with scope as option";
    }

    function test05() {
        // name: testSimpleValidationFail3
        local opts = {
            "a": 2
        };

        local err = validate([
            @() opts.a==1 || "ERRMSG"
        ], { throws=false });

        this.assertTrue(regexp(".*ERRMSG$").match(err));

        return "It invalidates a simple, valid table with no/automatic/default scope";
    }

    function test06() {
        // name: testTestFuncEvalsNull
        local err = validate([
            @() null
        ], { throws=false });

        this.assertEqual(null, err);

        return "Test funcs returning null are treated as passed";
    }

    function test07() {
        // name: testTestFuncEvalsTrue
        local err = validate([
            @() true
        ], { throws=false });

        this.assertEqual(null, err);

        return "Test funcs returning true are treated as passed";
    }

    function test08() {
        // name: testTestFuncEvalsString
        local err = validate([
            @() "ERRMSG"
        ], { throws=false });

        this.assertTrue(err != null);

        return "Test funcs returning strings are treated as failed";
    }

    function test09() {
        // name: testTestValEvalsNull
        local err = validate([
            null
        ], { throws=false });

        this.assertEqual(null, err);

        return "Test vals equal to null are treated as passed";
    }

    function test10() {
        // name: testTestValEvalsTrue
        local err = validate([
            true
        ], { throws=false });

        this.assertEqual(null, err);

        return "Test vals equal to true are treated as passed";
    }

    function test11() {
        // name: testTestValEvalsString
        local err = validate([
            "ERRMSG"
        ], { throws=false });

        this.assertTrue(err != null);

        return "Test vals equal to strings are treated as failed";
    }

    function test12() {
        // name: testMultipleErrors
        local err = validate([
            "ERRMSG1",
            "ERRMSG2",
            "ERRMSG3"
        ], { throws=false, tryAll=true });

        local errs = split(err, "\n");

        this.assertTrue(errs.len() == 3, format("Got %d errors instead of 3", errs.len()));
        for (local i = 1; i <= 3; i++) {
            local e = errs[i-1];
            local lastChar = e.slice(e.len()-1) == i.tostring();
            this.assertTrue(lastChar, "assertion failed on string: \"" + e + "\" with i: " + i.tostring());
        }

        return "Reports multiple errors when tryAll is set";
    }

}
