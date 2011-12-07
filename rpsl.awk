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
###         is 25000 which tends to make files ~100MB is size.
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

BEGIN {
    if (!base) {
	base = "whois://whois.ripe.net";
    }
    if (!outbase) {
	outbase = "rpsl";
    }
    if (!chunk) {
	chunk = 25000;
    }
    inobj = "false";
    nrecords = 0;
    fileno = -1;
    newfile();
}

/^$/ {
    if (inobj == "true") {
	print " ." >outfile
	nrecords += 1;
	if (nrecords % chunk == 0) {
	    newfile();
	}
    }
    inobj = "false";
    print >outfile;
}

/^as-block:/ {
    inobj = "true";
    printf("<%s/%s-%s> a rpsl:AutonomousSystemBlock", base, $2, $4) >outfile;
    gsub(/AS/, "");
    printf(";\n\trpsl:startAutNum \"%s\"^^xsd:integer", $2) >outfile;
    printf(";\n\trpsl:endAutNum \"%s\"^^xsd:integer", $4) >outfile;
}

/^as-set:/ {
    inobj = "true";
    printf("<%s/%s> a rpsl:AutonomousSystemSet", base, $2) >outfile;
}

/^aut-num:/ {
    inobj = "true";
    printf("<%s/%s> a rpsl:AutonomousSystem", base, $2) >outfile;
    sub(/^aut-num:[\t ]*AS/, "");
    printf(";\n\trpsl:autNum \"%s\"^^xsd:integer", $0) >outfile;
}

/^inetnum:/ {
    inobj = "true";
    start_addr = $2;
    ## todo calculate mask
    end_addr = $4;
}

/^netname:/ {
    if (inobj == "true") {
	printf("<%s/%s> a rpsl:Network", base, $2) >outfile;
	printf(";\n\tnet:address [ net:family net:IP4; net:addr \"%s\" ]", start_addr) >outfile;
    }
    
}

/^route:/ {
    inobj = "true";
    printf("<%s/%s> a rpsl:Route", base, $2) >outfile;
    sub(/^route:[\t ]*/, "");
    sub(/^/, "[ net:family net:IP4; net:addr \"");
    sub(/\//, "\"; net:prefix \"");
    sub(/$/, "\"^^xsd:integer ]");
    printf(";\n\tnet:address %s", $0) >outfile;
}

/^origin:/ {
    if (inobj == "true") {
	printf(";\n\trpsl:origin <%s/%s>", base, $2) >outfile;
    }
}

/^organisation:/ {
    inobj = "true";
    printf("<%s/%s> a foaf:Organisation", base, $2) >outfile;
}

/^address:/ {
    if (inobj == "true") {
	sub(/^address:[\t ]*/, "");
	printf(";\n\tdc:description \"\"\"%s\"\"\"", literal($0)) >outfile;
    }
}

/^domain:/ {
    inobj = "true";
    printf("<dns:%s> a rpsl:Domain", $2) >outfile;
}

/^nserver:/ {
    if (inobj == "true") {
	printf(";\n\trpsl:nameserver <dns:%s>", $2) >outfile;
    }
}

/^descr:/ {
    if (inobj == "true" && $2 != "") {
	sub(/^[^:]*:[\t ]*/, "");
	printf(";\n\tdc:description \"\"\"%s\"\"\"", literal($0)) >outfile;
    }
}

/^as-name:/ {
    if (inobj == "true") {
	printf(";\n\tdc:identifier \"%s\"", literal($2)) >outfile;
    }
}

/^changed:/ {
    if (inobj == "true") {
	printf(";\n\trpsl:changedBy [ foaf:mbox <mailto:%s> ]", $2) >outfile;
	printf(";\n\tdc:modified \"%s\"", literal($3)) >outfile;
    }
}

/^members:/ {
    if (inobj == "true") {
	sub(/^members:[\t ]*/, "");
	gsub(/,/, " ");
	gsub(/\t/, " ");
	gsub(/  */, " ");
	split($0, members, " ");
	for (m in members) {
	    printf(";\n\trpsl:member <%s/%s>", base, members[m]) >outfile;
	}
    }
}

/^org:/ {
    if (inobj == "true") {
	printf(";\n\trpsl:organisation <%s/%s>", base, $2) >outfile;
    }
}

/^admin-c:/ {
    if (inobj == "true") {
	printf(";\n\trpsl:adminContact <%s/%s>", base, $2) >outfile;
    }
}

/^tech-c:/ {
    if (inobj == "true") {
	printf(";\n\trpsl:techContact <%s/%s>", base, $2) >outfile;
    }
}

/^mnt-by:/ {
    if (inobj == "true") {
	printf(";\n\trpsl:maintainer <%s/%s>", base, $2) >outfile;
    }
}

/^mnt-routes:/ {
    if (inobj == "true") {
	printf(";\n\trpsl:routeMaintainer <%s/%s>", base, $2) >outfile;
    }
}

/^mnt-domains:/ {
    if (inobj == "true") {
	printf(";\n\trpsl:domainMaintainer <%s/%s>", base, $2) >outfile;
    }
}

/^mnt-lower:/ {
    if (inobj == "true") {
	printf(";\n\trpsl:lowerMaintainer <%s/%s>", base, $2) >outfile;
    }
}

/^source:/ {
    if (inobj == "true") {
	printf(";\n\tdc:source \"%s\"", $2) >outfile;
    }
}

END {
    if (inobj == "true") {
	printf(".\n") >outfile;
    }
}