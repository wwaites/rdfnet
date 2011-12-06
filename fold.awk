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