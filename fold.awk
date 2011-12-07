###
### This is intended to take RPSL input and fold entries 
### that span multiple lines into one line with \n characters
### as an intermediate step.
###

## fix escaping. remove all backslashes. escape double quotes.
function escape(s) {
    ns = gensub(/\\/, "", "g", s)
    return gensub(/"/, "\\\\\"", "g", ns);
}

BEGIN {
    record = "";
}

/^[^\t ]/ {
    if (record != "") {
	print record;
    }
    record = escape($0);
}

/^[\t ]/ {
    sub(/^[\t ]*/, "")
    record = sprintf("%s\\n%s", record, escape($0));
}

/^$/ {
    if (record != "") {
	print record;
    }
    record = "";
    print;
}

END {
    if (record != "") {
	print record;
    }
}