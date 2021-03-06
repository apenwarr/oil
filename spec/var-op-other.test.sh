#!/usr/bin/env bash
#
# Test combination of var ops.
#
# NOTE: There are also slice tests in {array,arith-context}.test.sh.

#### String length
v=foo
echo ${#v}
## stdout: 3

#### Unicode string length (UTF-8)
v=$'_\u03bc_'
echo ${#v}
## stdout: 3
## N-I dash stdout: 9
## N-I mksh stdout: 4

#### Unicode string length (spec/testdata/utf8-chars.txt)
v=$(cat spec/testdata/utf8-chars.txt)
echo ${#v}
## stdout: 7
## N-I dash stdout: 13
## N-I mksh stdout: 13

#### String length with incomplete utf-8
for num_bytes in 0 1 2 3 4 5 6 7 8 9 10 11 12 13; do
  s=$(head -c $num_bytes spec/testdata/utf8-chars.txt)
  echo ${#s}
done
## STDOUT:
0
1
2
-1
3
4
-1
-1
5
6
-1
-1
-1
7
## END
## STDERR:
osh warning: Incomplete UTF-8 character
osh warning: Incomplete UTF-8 character
osh warning: Incomplete UTF-8 character
osh warning: Incomplete UTF-8 character
osh warning: Incomplete UTF-8 character
osh warning: Incomplete UTF-8 character
## END
# zsh behavior actually matches bash!
## BUG bash/zsh stderr-json: ""
## BUG bash/zsh STDOUT:
0
1
2
3
3
4
5
6
5
6
7
8
9
7
## END
## BUG dash/mksh stderr-json: ""
## N-I dash/mksh STDOUT:
0
1
2
3
4
5
6
7
8
9
10
11
12
13
## END

#### String length with invalid utf-8 continuation bytes
for num_bytes in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14; do
  s=$(head -c $num_bytes spec/testdata/utf8-chars.txt)$(echo -e "\xFF")
  echo ${#s}
done
## STDOUT:
-1
-1
-1
-1
-1
-1
-1
-1
-1
-1
-1
-1
-1
-1
-1
## END
## STDERR:
osh warning: Invalid start of UTF-8 character
osh warning: Invalid start of UTF-8 character
osh warning: Invalid start of UTF-8 character
osh warning: Invalid UTF-8 continuation byte
osh warning: Invalid start of UTF-8 character
osh warning: Invalid start of UTF-8 character
osh warning: Invalid UTF-8 continuation byte
osh warning: Invalid UTF-8 continuation byte
osh warning: Invalid start of UTF-8 character
osh warning: Invalid start of UTF-8 character
osh warning: Invalid UTF-8 continuation byte
osh warning: Invalid UTF-8 continuation byte
osh warning: Invalid UTF-8 continuation byte
osh warning: Invalid start of UTF-8 character
osh warning: Invalid start of UTF-8 character
## END
## BUG bash/zsh stderr-json: ""
## BUG bash/zsh STDOUT:
1
2
3
4
4
5
6
7
6
7
8
9
10
8
8
## N-I dash stderr-json: ""
## N-I dash STDOUT:
7
8
9
10
11
12
13
14
15
16
17
18
19
20
20
## END
## N-I mksh stderr-json: ""
## N-I mksh STDOUT:
1
2
3
4
5
6
7
8
9
10
11
12
13
14
14
## END

#### Length of undefined variable
echo ${#undef}
## stdout: 0

#### Length of undefined variable with nounset
set -o nounset
echo ${#undef}
## status: 1
## OK dash status: 2

#### Cannot take length of substring slice
# These are runtime errors, but we could make them parse time errors.
v=abcde
echo ${#v:1:3}
## status: 1
## OK osh status: 2
## N-I dash status: 0
## N-I dash stdout: 5
# zsh actually implements this!
## OK zsh stdout: 3
## OK zsh status: 0

#### Pattern replacement
v=abcde
echo ${v/c*/XX}
## stdout: abXX
## N-I dash status: 2
## N-I dash stdout-json: ""

#### Pattern replacement on unset variable
echo -${v/x/y}-
echo status=$?
set -o nounset  # make sure this fails
echo -${v/x/y}-
## STDOUT:
--
status=0
## BUG mksh STDOUT:
# patsub disrespects nounset!
--
status=0
--
## status: 1
## BUG mksh status: 0
## N-I dash status: 2
## N-I dash stdout-json: ""

#### Global Pattern replacement with /
s=xx_xx_xx
echo ${s/xx?/yy_} ${s//xx?/yy_}
## stdout: yy_xx_xx yy_yy_xx
## N-I dash status: 2
## N-I dash stdout-json: ""

#### Left Anchored Pattern replacement with #
s=xx_xx_xx
echo ${s/?xx/_yy} ${s/#?xx/_yy}
## stdout: xx_yy_xx xx_xx_xx
## N-I dash status: 2
## N-I dash stdout-json: ""

#### Right Anchored Pattern replacement with %
s=xx_xx_xx
echo ${s/?xx/_yy} ${s/%?xx/_yy}
## stdout: xx_yy_xx xx_xx_yy
## N-I dash status: 2
## N-I dash stdout-json: ""

#### Replace fixed strings
s=xx_xx
echo ${s/xx/yy} ${s//xx/yy} ${s/#xx/yy} ${s/%xx/yy}
## stdout: yy_xx yy_yy yy_xx xx_yy
## N-I dash status: 2
## N-I dash stdout-json: ""

#### Replace is longest match
# If it were shortest, then you would just replace the first <html>
s='begin <html></html> end'
echo ${s/<*>/[]}
## stdout: begin [] end
## N-I dash status: 2
## N-I dash stdout-json: ""

#### Replace char class
s=xx_xx_xx
echo ${s//[[:alpha:]]/y} ${s//[^[:alpha:]]/-}
## stdout: yy_yy_yy xx-xx-xx
## N-I mksh stdout: xx_xx_xx xx_xx_xx
## N-I dash status: 2
## N-I dash stdout-json: ""

#### Replace hard glob
s='aa*bb+cc'
echo ${s//\**+/__}  # Literal *, then any sequence of characters, then literal +
## stdout: aa__cc
## N-I dash status: 2
## N-I dash stdout-json: ""

#### Pattern replacement ${v/} is not valid
v=abcde
echo -${v/}-
echo status=$?
## status: 2
## stdout-json: ""
## N-I dash status: 2
## N-I dash stdout-json: ""
## BUG bash/mksh/zsh status: 0
## BUG bash/mksh/zsh stdout-json: "-abcde-\nstatus=0\n"

#### Pattern replacement ${v//} is not valid
v='a/b/c'
echo -${v//}-
echo status=$?
## status: 2
## stdout-json: ""
## N-I dash status: 2
## N-I dash stdout-json: ""
## BUG bash/mksh/zsh status: 0
## BUG bash/mksh/zsh stdout-json: "-a/b/c-\nstatus=0\n"

#### ${v/a} is the same as ${v/a/}  -- no replacement string
v='aabb'
echo ${v/a}
echo status=$?
## stdout-json: "abb\nstatus=0\n"
## N-I dash stdout-json: ""
## N-I dash status: 2

#### String slice
foo=abcdefg
echo ${foo:1:3}
## STDOUT:
bcd
## END
## N-I dash status: 2
## N-I dash stdout-json: ""

#### Out of range string slice: begin
# out of range begin doesn't raise error in bash, but in mksh it skips the
# whole thing!
foo=abcdefg
echo _${foo:100:3}
echo $?
## STDOUT:
_
0
## END
## BUG mksh stdout-json: "\n0\n"
## N-I dash status: 2
## N-I dash stdout-json: ""

#### Out of range string slice: length
# OK in both bash and mksh
foo=abcdefg
echo _${foo:3:100}
echo $?
## STDOUT:
_defg
0
## END
## BUG mksh stdout-json: "_defg\n0\n"
## N-I dash status: 2
## N-I dash stdout-json: ""

#### String slice: negative begin
foo=abcdefg
echo ${foo: -4:3}
## OK osh stdout:
## stdout: def
## N-I dash status: 2
## N-I dash stdout-json: ""

#### String slice: negative second arg is position, not length
foo=abcdefg
echo ${foo:3:-1} ${foo: 3: -2} ${foo:3 :-3 }
## OK osh stdout:
## stdout: def de d
## BUG mksh stdout: defg defg defg
## N-I dash status: 2
## N-I dash stdout-json: ""

#### strict-word-eval with string slice
set -o strict-word-eval || true
echo slice
s='abc'
echo -${s: -2}-
## stdout-json: "slice\n"
## status: 1
## N-I bash status: 0
## N-I bash stdout-json: "slice\n-bc-\n"
## N-I dash status: 2
## N-I dash stdout-json: ""
## N-I mksh/zsh status: 1
## N-I mksh/zsh stdout-json: ""

#### String slice with math
# I think this is the $(()) language inside?
i=1
foo=abcdefg
echo ${foo: i+4-2 : i + 2}
## stdout: def
## N-I dash status: 2
## N-I dash stdout-json: ""

#### Slice undefined
echo -${undef:1:2}-
set -o nounset
echo -${undef:1:2}-
echo -done-
## STDOUT:
--
## END
## status: 1
# mksh doesn't respect nounset!
## BUG mksh status: 0
## BUG mksh STDOUT:
--
--
-done-
## END
## N-I dash status: 2
## N-I dash stdout-json: ""

#### Slice UTF-8 String
# mksh slices by bytes.
foo='--μ--'
echo ${foo:1:3}
## stdout: -μ-
## BUG mksh stdout: -μ
## N-I dash status: 2
## N-I dash stdout-json: ""

#### Slice string with invalid UTF-8 results in empty string and warning
s=$(echo -e "\xFF")bcdef
echo -${s:1:3}-
## status: 0
## stdout-json: "--\n"
## stderr-json: "osh warning: Invalid start of UTF-8 character\n"
## BUG bash/mksh/zsh status: 0
## BUG bash/mksh/zsh stdout-json: "-bcd-\n"
## BUG bash/mksh/zsh stderr-json: ""
## N-I dash status: 2
## N-I dash stdout-json: ""
## N-I dash stderr-json: "_tmp/spec-bin/dash: 2: Bad substitution\n"


#### Slice string with invalid UTF-8 with strict-word-eval
set -o strict-word-eval || true
echo slice
s=$(echo -e "\xFF")bcdef
echo -${s:1:3}-
## status: 1
## stdout-json: "slice\n"
## N-I mksh/zsh status: 1
## N-I mksh/zsh stdout-json: ""
## N-I dash status: 2
## N-I dash stdout-json: ""
## N-I bash status: 0
## N-I bash stdout-json: "slice\n-bcd-\n"

#### Lower Case with , and ,,
x='ABC DEF'
echo ${x,}
echo ${x,,}
## STDOUT:
aBC DEF
abc def
## END
## N-I dash/mksh/zsh stdout-json: ""
## N-I dash status: 2
## N-I mksh/zsh status: 1


#### Upper Case with ^ and ^^
x='abc def'
echo ${x^}
echo ${x^^}
## STDOUT:
Abc def
ABC DEF
## END
## N-I dash/mksh/zsh stdout-json: ""
## N-I dash status: 2
## N-I mksh/zsh status: 1

#### Lower Case with constant string (VERY WEIRD)
x='AAA ABC DEF'
echo ${x,A}
echo ${x,,A}  # replaces every A only?
## STDOUT:
aAA ABC DEF
aaa aBC DEF
## END
## N-I dash/mksh/zsh stdout-json: ""
## N-I dash status: 2
## N-I mksh/zsh status: 1

#### Lower Case glob
x='ABC DEF'
echo ${x,[d-f]}
echo ${x,,[d-f]}  # This seems buggy, it doesn't include F?
## STDOUT:
ABC DEF
ABC deF
## END
## N-I dash/mksh/zsh stdout-json: ""
## N-I dash status: 2
## N-I mksh/zsh status: 1
