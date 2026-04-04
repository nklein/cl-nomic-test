# cl-nomic-game Implementation

Caveat: Take this document with a grain of salt.
It was written to describe the initial implementation before any pull-requests are merged.
There is a high-likelihood that pull-requests will change
either the implementation or this document without changing both.

The object of this nomic game is to have the code in this repository decide that you are the winner.

The implementation receives a list of open pull requests for this repository on standard input
and outputs a single JSON response decision on standard output.

**Important Things to Note About The Initial Implementation:**
* If your GitHub login name is not one of the ones in the `*PLAYERS*` list, your pull requests will be ignored.
* If your GitHub login name is not one of the ones in the `*PLAYERS*` list, your votes on other pull requests will be ignored.
* If your vote on a pull request is on a revision that is no longer the head of the pull request, your vote no longer counts.
* Voting on a pull request is, regrettably, tricky. (See the [**How to Vote** section](#how-to-vote) below.)

## [How to Vote]

Unfortunately, GitHub has a mechanism whereby a reviewer can mark a pull request as approve.
They do not, however, have a mechanism by which a reviewer can mark a pull request as rejected.

Furthermore, pull-request comments are not easy to order against commits.
Reviews, on the other hand, are tied to a particular commit.

To eliminate ambiguity about whether something is accepted or rejected, this code requires a review comment that is precisely (as in, string-compare) equivalent to the text `ACCEPT` or the text `REJECT` to consider it a vote.

To avoid abuse where one pushes a malicious modification to a pull-request after everyone has
voted to approve it, only review comments are considered by the initial implementation here.

To submit a review, you should navigate to the pull request on the GitHub website.
From there, you can click on the `Files changed` tab.
There is a green button on the right side of the top of the tab that reads **Submit review**.
Click on it.
It will open a drop-down form.
Enter either `ACCEPT` or `REJECT` (with no newlines or spaces or any other text).
Make sure you have `Comment` selected from the radio buttons.
Then, press the **Submit review** button at the bottom of the drop-down form.

## Implementation in More Depth

### [Decision Classes]

There are decision classes implemented in `src/decision.lisp`.
The generic function `JSON-OBJECT` will convert any of those to the JSON version appropriate for standard output.

The decision classes that the initial implementation will emit to standard output are:
* `(make-accept-decision :id {augmented id} :message <optional-string>)`
* `(make-reject-decision :id {augmented id} :message <optional-string>)`
* `(make-defer-decision)`

See the [**Json Utilities** section](#json-utilities) below for more information
about the reader-macro featured in the above examples.

To win, it would be convenient for you to emit this message:
* `(make-winner-decision :name <name-of-winner> :message <optional-string>)`

The initial implementation **never** creates a winner decision.

### [Json Utilities]

There are a number of functions for handling input and output JSON in `src/json-utils.lisp`.
There is also a reader-macro defined in `src/reader-macro.lisp` that supports querying JSON objects.

The `JSON-PARSE` function takes either a string or a stream as an argument and returns
the `YASON` parse from the input string or stream.

    (defun json-parse (string-or-stream) ...) => lisp-representation-of-json

The `YASON` parse represents a JSON object as Lisp `HASH-TABLE`.

The converse operations are `JSON-ENCODE` to output to a stream or `JSON-ENCODE*` to output to a string.

    (defun json-encode (json-object &optional stream) ...)   ;; output to stream
    (defun json-encode* (json-object) ...) => json-string

The `JSON-ATTR` method can be used to retrieve an element from the Lisp representation of the JSON object.

    (defun json-attr (property-name json-object &optional default) ...) => value-of-property-or-default

For convenience when diving multiple levels into a JSON object, the code defines a reader macro
that is of the form `{json-object &rest property-names}`. For example, I might do something like:

    {(get-pull-request-by-id 3) head user login}

This is usually more convenient than the equivalent:

    (json-attr "login" (json-attr "user" (json-attr "head" (get-pull-request-by-id 3))))

There is a generic function `JSON-OBJECT` for turning some types of data into JSON objects.

    (defgeneric json-object (src))

There is a specialization for turning an alist into a JSON object:

    (json-encode (json-object (list (cons "a" 1) (cons "b" 2))) *standard-output*) => prints

      {
        "a": 1,
        "b": 2
      }

There are also specializations for the decision class described in the [**Decision classes** section](#decision-classes) above.

There is also a method for turning a JSON object into an alist:

    (defun json-object-to-alist (json-object) ...) => alist

### How the Initial Implementation Makes Decisions

The decision logic is implemented in the `DECIDE` function in `src/decide.lisp`.

That function takes the list of "augmented pull requests" (see the [**Augmented Pull Requests** section](#augmented-pull-requests) below).
It makes a shallow copy of the list and sorts the items by the `{item pull_request updated_at}` timestamps.
The sorting is from oldest to newest.

Given the sorted list:
* it goes through to find the first one that it wants to reject,
* if it didn't find one to reject, it goes through to find one to accept,
* and if it still hasn't found anything, it emits a defer decision.

The `src/players.lisp` contains an array of `*PLAYERS*` and defines a function:

    (defun relevant-player-login-p (login) ...) => the player struct in the *PLAYERS* list with that login

#### When to reject a pull request

The `FIND-REJECT` function is used with `CL:REDUCE` to return the first
instance in the list of augmented pull requests that should be rejected.

The implementation will reject any pull request that was made by a user with a login
that garners a `NIL` return from `RELEVANT-PLAYER-LOGIN-P`.

If it hasn't rejected an augmented pull request for that reason, it tallies up
the `ACCEPT` or `REJECT` votes from relevant players on the `HEAD` of the pull request.
If half or more of the relevant players have voted to `REJECT`, the pull request is rejected.
*Note:* 50% of the relevant players voting `REJECT` will kill a pull request.

#### When to accept a pull request

The `FIND-ACCEPT` function is used with `CL:REDUCE` to return the first
instance in the list of augmented pull requests that should be accepted.

The code tallies up the `ACCEPT` or `REJECT` votes from relevant players on the `HEAD` of the pull request.
If more than half of the relevant players have voted to `ACCEPT`, the pull request is accepted.
*Note:* 50% of the relevant players voting `ACCEPT` is not enough to approve a pull request.


#### How votes are tallied

The votes are tallied by sorting the `{augmented-pull-request reviews}` list by their `submitted_at`
timestamp from oldest to newest.

If a particular review is from a user login that garners a `NIL` from `RELEVANT-USER-LOGIN-P`, the
review is ignored.

If a particular review is for a revision that is no longer the head of the pull-request, the review is ignored.

If the review is not **exactly** the text `ACCEPT` or the text `REJECT`, the review is ignored.

From what's left, the code collects the most recent `ACCEPT` or `REJECT` by user login.
It then counts the number of `ACCEPT` votes and the number of `REJECT` votes.

When determining proportions, the numerator is either the number of `ACCEPT` votes
or the number of `REJECT` votes whilst the denominator is the total number of entries
in the `*PLAYERS*` list.

## [Augmented Pull Requests]

The supervisor gives this code a list of augmented pull requests on standard input.

An augmented pull request is:
* an `id` number (unique during this run) for the augmented pull request,
* the `pull_request` returned by the [*Get a pull request* GitHub API](https://docs.github.com/en/rest/pulls/pulls?apiVersion=2026-03-10#get-a-pull-request),
* the list of `reviews` on the pull request returned by the [*List reviews for a pull request* GitHub API](https://docs.github.com/en/rest/pulls/reviews?apiVersion=2026-03-10#list-reviews-for-a-pull-request),
* the list of `comments` on the pull request returned by the [*List issue comments* GitHub API](https://docs.github.com/en/rest/issues/comments?apiVersion=2026-03-10#list-issue-comments) (Note: all pull requests are issues, but not all issues are pull requests), and
* the list of `commits` on the pull request returned by [*List commits on a pull request* GitHub API](https://docs.github.com/en/rest/pulls/pulls?apiVersion=2026-03-10#list-commits-on-a-pull-request).

These are all wrapped together in a JSON object.

    {
      "id": id-number,
      "pull_request": pull-request-object,
      "reviews": array-of-reviews,
      "comments": array-of-comments,
      "commits": array-of-commits
    }
