###
### This script will convert an RPSL database into many Turtle
### files.
###
### The following variables may be provided on the command line:
###
### base - base URI for entities, default whois://whois.ripe.net
###        note no trailing slash!
### outbase - basename for the output files, default rpsl
### chunk - chunk size, number of records per output file, default
###         is 100000.
###

## fix escaping for literals. only allow \n and \" to
## be escaped
function literal(s) {
    p = gensub(/^"/, "\\\\\"", "g", s)
    q = gensub(/([^\\])"/, "\\1\\\\\"", "g", p);
    return gensub(/\\([^nrt"])/, "\\1", "g", q);
}

function header() {
    print "@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>." >outfile;
    print "@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#>." >outfile;
    print "@prefix owl: <http://www.w3.org/2002/07/owl#>." >outfile;
    print "@prefix xsd: <http://www.w3.org/2001/XMLSchema#>." >outfile;
    print "@prefix dc: <http://purl.org/dc/terms/>." >outfile;
    print "@prefix foaf: <http://xmlns.com/foaf/0.1/>." >outfile;
    print "@prefix skos: <http://www.w3.org/2004/02/skos/core#>." >outfile;
    print "@prefix net: <http://river.styx.org/network#>." >outfile;
    print "@prefix rpsl: <http://river.styx.org/rpsl#>." >outfile;
    print >outfile;
}

function newfile() {
    fileno += 1;
    outfile = sprintf("%s%08d.ttl", outbase, fileno);
    header();
}

function newobj() {
    if (inobj == "true") {
	writeobj();
    }
    delete obj;
    objidx = 0;
    inobj = "true";
}

function append(s) {
    if (inobj == "true") {
	obj[objidx] = s;
	objidx++;
    }
}

function writeobj() {
    if (inobj == "true") {
	for (i=0; i<objidx; i++) {
	    printf("%s", obj[i]) >outfile;
	}
	printf(".\n\n") >outfile;
	inobj = "false";
    }
}

BEGIN {
    if (!base) {
	base = "whois://whois.ripe.net";
    }
    if (!outbase) {
	outbase = "rpsl";
    }
    if (!chunk) {
	chunk = 100000;
    }
    inobj = "false";
    nrecords = 0;
    fileno = -1;
    newfile();
}

/^$/ {
    if (inobj == "true") {
	nrecords += 1;
	if (nrecords % chunk == 0) {
	    newfile();
	}
    }
}

/^as-block:/ {
    newobj();
    append(sprintf("<%s/%s-%s> a rpsl:AutonomousSystemBlock", base, $2, $4));
    gsub(/AS/, "");
    append(sprintf(";\n\trpsl:startAutNum \"%s\"^^xsd:integer", $2));
    append(sprintf(";\n\trpsl:endAutNum \"%s\"^^xsd:integer", $4));
}

/^as-set:/ {
    newobj();
    append(sprintf("<%s/%s> a rpsl:AutonomousSystemSet", base, $2));
}

/^aut-num:/ {
    newobj();
    append(sprintf("<%s/%s> a rpsl:AutonomousSystem", base, $2));
    sub(/^aut-num:[\t ]*AS/, "");
    append(sprintf(";\n\trpsl:autNum \"%s\"^^xsd:integer", $0));
}

/^inetnum:/ {
    newobj();
    start_addr = $2;
    ## todo calculate mask
    end_addr = $4;
    append("_:placeholder a rpsl:Network");
    append(";\n\tnet:address [];");
}

/^netname:/ {
    if (inobj == "true") {
	obj[0] = sprintf("<%s/%s> a rpsl:Network", base, $2);
	obj[1] = sprintf(";\n\tnet:address [ net:family net:IP4; net:addr \"%s\" ]", start_addr);
    }
}

/^route:/ {
    newobj();
    append(sprintf("<%s/%s> a rpsl:Route", base, $2));
    sub(/^route:[\t ]*/, "");
    sub(/^/, "[ net:family net:IP4; net:addr \"");
    sub(/\//, "\"; net:prefix \"");
    sub(/$/, "\"^^xsd:integer ]");
    append(sprintf(";\n\tnet:address %s", $0));
}

/^origin:/ {
    append(sprintf(";\n\trpsl:origin <%s/%s>", base, $2));
}

/^organisation:/ {
    newobj();
    append(sprintf("<%s/%s> a foaf:Organisation", base, $2));
}

/^address:/ {
    sub(/^address:[\t ]*/, "");
    append(sprintf(";\n\tdc:description \"\"\"%s\"\"\"", literal($0)));
}

/^domain:/ {
    newobj();
    append(sprintf("<dns:%s> a rpsl:Domain", $2));
}

/^nserver:/ {
    append(sprintf(";\n\trpsl:nameserver <dns:%s>", $2));
}

/^descr:/ {
    if ($2 != "") {
	sub(/^[^:]*:[\t ]*/, "");
	append(sprintf(";\n\tdc:description \"\"\"%s\"\"\"", literal($0)));
    }
}

/^as-name:/ {
    append(sprintf(";\n\tdc:identifier \"%s\"", literal($2)));
}

/^changed:/ {
    append(sprintf(";\n\trpsl:changedBy [ foaf:mbox <mailto:%s> ]", $2));
    append(sprintf(";\n\tdc:modified \"%s\"", literal($3)));
}

/^members:/ {
    sub(/^members:[\t ]*/, "");
    gsub(/,/, " ");
    gsub(/\t/, " ");
    gsub(/  */, " ");
    split($0, members, " ");
    for (m in members) {
	append(sprintf(";\n\trpsl:member <%s/%s>", base, members[m]));
    }
}

/^org:/ {
    append(sprintf(";\n\trpsl:organisation <%s/%s>", base, $2));
}

/^admin-c:/ {
    append(sprintf(";\n\trpsl:adminContact <%s/%s>", base, $2));
}

/^tech-c:/ {
    append(sprintf(";\n\trpsl:techContact <%s/%s>", base, $2));
}

/^zone-c:/ {
    append(sprintf(";\n\trpsl:zoneContact <%s/%s>", base, $2));
}

/^mnt-by:/ {
    append(sprintf(";\n\trpsl:maintainer <%s/%s>", base, $2));
}

/^mnt-routes:/ {
    append(sprintf(";\n\trpsl:routeMaintainer <%s/%s>", base, $2));
}

/^mnt-domains:/ {
    append(sprintf(";\n\trpsl:domainMaintainer <%s/%s>", base, $2));
}

/^mnt-lower:/ {
    append(sprintf(";\n\trpsl:lowerMaintainer <%s/%s>", base, $2));
}

/^source:/ {
    append(sprintf(";\n\tdc:source \"%s\"", $2));
}

END {
    writeobj();
}