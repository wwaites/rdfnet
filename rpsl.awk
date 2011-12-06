###
### This script will convert an RPSL database into Turtle
###
### It has a configurable variable called "base" which is
### used to form the base of URIs.
###

## fix escaping for literals. only allow \n and \" to
## be escaped
function literal(s) {
    p = gensub(/^"/, "\\\\\"", "g", s)
    q = gensub(/([^\\])"/, "\\1\\\\\"", "g", p);
    return gensub(/\\([^nrt"])/, "\\1", "g", q);
}

BEGIN {
    print "@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>.";
    print "@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#>.";
    print "@prefix owl: <http://www.w3.org/2002/07/owl#>.";
    print "@prefix xsd: <http://www.w3.org/2001/XMLSchema#>.";
    print "@prefix dc: <http://purl.org/dc/terms/>.";
    print "@prefix foaf: <http://xmlns.com/foaf/0.1/>.";
    print "@prefix skos: <http://www.w3.org/2004/02/skos/core#>.";
    print "@prefix net: <http://river.styx.org/network#>.";
    print "@prefix rpsl: <http://river.styx.org/rpsl#>.";
    print;
    inobj = "false";
    if (!base) {
	base = "whois://whois.ripe.net";
    }
}

/^$/ {
    if (inobj == "true") {
	print " ."
    }
    inobj = "false";
    print
}

/^as-block:/ {
    inobj = "true";
    printf("<%s/%s-%s> a rpsl:AutonomousSystemBlock", base, $2, $4);
    gsub(/AS/, "");
    printf(";\n\trpsl:startAutNum \"%s\"^^xsd:integer", $2);
    printf(";\n\trpsl:endAutNum \"%s\"^^xsd:integer", $4);
}

/^as-set:/ {
    inobj = "true";
    printf("<%s/%s> a rpsl:AutonomousSystemSet", base, $2);
}

/^aut-num:/ {
    inobj = "true";
    printf("<%s/%s> a rpsl:AutonomousSystem", base, $2);
    sub(/^aut-num:[\t ]*AS/, "");
    printf(";\n\trpsl:autNum \"%s\"^^xsd:integer", $0);
}

/^inetnum:/ {
    inobj = "true";
    start_addr = $2;
    ## todo calculate mask
    end_addr = $4;
}

/^netname:/ {
    if (inobj == "true") {
	printf("<%s/%s> a rpsl:Network", base, $2);
	printf(";\n\tnet:address [ net:family net:IP4; net:addr \"%s\" ]", start_addr);
    }
    
}

/^route:/ {
    inobj = "true";
    printf("<%s/%s> a rpsl:Route", base, $2);
    sub(/^route:[\t ]*/, "");
    sub(/^/, "[ net:family net:IP4; net:addr \"");
    sub(/\//, "\"; net:prefix \"");
    sub(/$/, "\"^^xsd:integer ]");
    printf(";\n\tnet:address %s", $0);
}

/^origin:/ {
    if (inobj == "true") {
	printf(";\n\trpsl:origin <%s/%s>", base, $2);
    }
}

/^organisation:/ {
    inobj = "true";
    printf("<%s/%s> a foaf:Organisation", base, $2);
}

/^address:/ {
    if (inobj == "true") {
	sub(/^address:[\t ]*/, "");
	printf(";\n\tdc:description \"\"\"%s\"\"\"", literal($0));
    }
}

/^domain:/ {
    inobj = "true";
    printf("<dns:%s> a rpsl:Domain", $2);
}

/^nserver:/ {
    if (inobj == "true") {
	printf(";\n\trpsl:nameserver <dns:%s>", $2);
    }
}

/^descr:/ {
    if (inobj == "true" && $2 != "") {
	sub(/^[^:]*:[\t ]*/, "");
	printf(";\n\tdc:description \"\"\"%s\"\"\"", literal($0));
    }
}

/^as-name:/ {
    if (inobj == "true") {
	printf(";\n\tdc:identifier \"%s\"", $2);
    }
}

/^changed:/ {
    if (inobj == "true") {
	printf(";\n\trpsl:changedBy [ foaf:mbox <mailto:%s> ]", $2);
	printf(";\n\tdc:modified \"%s\"", $3);
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
	    printf(";\n\trpsl:member <%s/%s>", base, members[m]);
	}
    }
}

/^org:/ {
    if (inobj == "true") {
	printf(";\n\trpsl:organisation <%s/%s>", base, $2);
    }
}

/^admin-c:/ {
    if (inobj == "true") {
	printf(";\n\trpsl:adminContact <%s/%s>", base, $2);
    }
}

/^tech-c:/ {
    if (inobj == "true") {
	printf(";\n\trpsl:techContact <%s/%s>", base, $2);
    }
}

/^mnt-by:/ {
    if (inobj == "true") {
	printf(";\n\trpsl:maintainer <%s/%s>", base, $2);
    }
}

/^mnt-routes:/ {
    if (inobj == "true") {
	printf(";\n\trpsl:routeMaintainer <%s/%s>", base, $2);
    }
}

/^mnt-domains:/ {
    if (inobj == "true") {
	printf(";\n\trpsl:domainMaintainer <%s/%s>", base, $2);
    }
}

/^mnt-lower:/ {
    if (inobj == "true") {
	printf(";\n\trpsl:lowerMaintainer <%s/%s>", base, $2);
    }
}

/^source:/ {
    if (inobj == "true") {
	printf(";\n\tdc:source \"%s\"", $2);
    }
}

END {
    if (inobj == "true") {
	printf(".\n");
    }
}