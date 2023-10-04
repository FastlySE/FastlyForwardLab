terraform {
  required_providers {
    sigsci = {
      source = "signalsciences/sigsci"
	  version = "1.2.2"
    }
  }
}

variable "NGWAF_CORP" {
    type        = string
    description = "This is the corp where configuration changes will be made as an env variable."
}
variable "NGWAF_EMAIL" {
    type        = string
    description = "This is the email address associated with the token for the Sig Sci API as an env variable."
}
variable "NGWAF_TOKEN" {
    type        = string
    description = "This is a secret token for the Sig Sci API as an env variable."
}
variable "NGWAF_SITE" {
    type        = string
    description = "This is the site for the Sig Sci API as an env variable."
}


# Supply API authentication
provider "sigsci" {
  corp = "${var.NGWAF_CORP}"
  email = "${var.NGWAF_EMAIL}"
  auth_token = "${var.NGWAF_TOKEN}"
}

## start Templated Rule

  resource "sigsci_site_templated_rule" "login_template_rule" {
  site_short_name = "${var.NGWAF_SITE}"
  name            = "LOGINATTEMPT"
  detections {
    enabled = "true"
    fields {
      name  = "path"
      value = "/login/*"
    }
  }

  alerts {
    long_name              = "alert 1"
    interval               = 10
    threshold              = 2
    skip_notifications     = true
    enabled                = true
    action                 = "template"
    block_duration_seconds = 120
  }
}

## End Templated Rule


### start OWASP-Attack rule site specific

resource "sigsci_site_signal_tag" "owasp-attack-signal" {
  site_short_name = "${var.NGWAF_SITE}"
  name            = "OWASP signal tag"
  description     = "OWASP Signal Tag"
}

resource "sigsci_site_rule" "owasp-attack-rule" {
  site_short_name = "${var.NGWAF_SITE}"
  type            = "request"
  group_operator  = "all"
  enabled         = "true"
  reason          = "OWASP Attacks"
  expiration      = ""
	
    actions {
        type   = "block"
    }

    conditions {
        field          = "signal"
        group_operator = "any"
        operator       = "exists"
        type           = "multival"

        conditions {
            field    = "signalType"
            operator = "equals"
            type     = "single"
            value    = "BACKDOOR"
        }
        conditions {
            field    = "signalType"
            operator = "equals"
            type     = "single"
            value    = "CMDEXE"
        }        
	 conditions {
            field    = "signalType"
            operator = "equals"
            type     = "single"
            value    = "LOG4J-JNDI"
        }
       conditions {
            field    = "signalType"
            operator = "equals"
            type     = "single"
            value    = "SQLI"
        }
        conditions {
            field    = "signalType"
            operator = "equals"
            type     = "single"
            value    = "TRAVERSAL"
        }
        conditions {
            field    = "signalType"
            operator = "equals"
            type     = "single"
            value    = "USERAGENT"
        }
        conditions {
            field    = "signalType"
            operator = "equals"
            type     = "single"
            value    = "XSS"
        }
    }
    actions {
    type = "addSignal"
    signal = "site.owasp-signal-tag" 
  }
  depends_on = [
  sigsci_site_signal_tag.owasp-attack-signal
  ]
}

### end OWASP attack rule

## Site Alert

resource "sigsci_site_alert" "XSS_Alert" {
  site_short_name        = "${var.NGWAF_SITE}"
  tag_name               = "site.owasp-signal-tag"
  long_name              = "OWASP Alerts"
  interval               = 10
  threshold              = 5
  enabled                = true
  action                 = "info"
  block_duration_seconds = 86400
}

## End Site Alert

### Start Anomaly Signals

resource "sigsci_site_signal_tag" "anomaly-attack" {
  site_short_name = "${var.NGWAF_SITE}"
  name            = "anomaly-attack"
  description     = "Identification of attacks from Anomaly traffic"
}

resource "sigsci_site_rule" "anomaly-attack" {
  site_short_name = "${var.NGWAF_SITE}"
  type            = "request"
  group_operator  = "all"
  enabled         = true
  reason          = "Blocking attacks from Anomaly Traffic"
  expiration      = ""

    actions {
        type   = "block"
        }

  conditions {
    type     = "multival"
    field    = "signal"
    group_operator = "any"
    operator = "exists"
    conditions {
      field = "signalType"
      operator = "equals"
      type = "single"
      value = "ABNORMALPATH"
    }
    conditions {
      field = "signalType"
      operator = "equals"
      type = "single"
      value = "CODEINJECTION"
    }
    conditions {
      field = "signalType"
      operator = "equals"
      type = "single"
      value = "DOUBLEENCODING"
    }
    conditions {
      field = "signalType"
      operator = "equals"
      type = "single"
      value = "DUPLICATE-HEADERS"
    }
    conditions {
      field = "signalType"
      operator = "equals"
      type = "single"
      value = "NOTUTF8"
    }
    conditions {
      field = "signalType"
      operator = "equals"
      type = "single"
      value = "MALFORMED-DATA"
    }
     conditions {
      field = "signalType"
      operator = "equals"
      type = "single"
      value = "NOUA"
    }
     conditions {
      field = "signalType"
      operator = "equals"
      type = "single"
      value = "PRIVATEFILE"
    }
     conditions {
      field = "signalType"
      operator = "equals"
      type = "single"
      value = "RESPONSESPLIT"
    }
	conditions {
      field    = "signalType"
      operator = "equals"
      type     = "single"
      value    = "NO-CONTENT-TYPE"
    }
  }
    actions {
    type = "addSignal"
    signal = "site.anomaly-attack" 
  }

}

## End Anomoly Signals
