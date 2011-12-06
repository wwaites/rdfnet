###
### This is intended to take RPSL input and fold entries 
### that span multiple lines into one line with \n characters
### as an intermediate step.
###
BEGIN {
    record = "";
}

/^[^\t ]/ {
    if (record != "") {
	print record;
    }
    record = $0;
}

/^[\t ]/ {
    sub(/^[\t ]*/, "")
    record = sprintf("%s\\n%s", record, $0);
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