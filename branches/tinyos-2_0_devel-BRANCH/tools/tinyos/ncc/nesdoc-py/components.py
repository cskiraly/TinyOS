# Copyright (c) 2005 Intel Corporation
# All rights reserved.
#
# This file is distributed under the terms in the attached INTEL-LICENSE     
# file. If you do not find these files, copies can be found by writing to
# Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
# 94704.  Attention:  Intel License Inquiry.

# Generate HTML file for a component

from nesdoc.utils import *
from nesdoc.generators import *
from nesdoc.html import *

__all__ = [ "generate_component" ]

# Output HTML describing a specification element
def spec_signature_html(ht, elem):
  if elem.tagName == "function":
    ht.pfnsig(elem, lambda (name): "<b>%s</b>" % name)
  else:
    assert elem.tagName == "interface"
    instance = xml_tag(elem, "instance")
    idef = xml_tag(instance, "interfacedef-ref")
    arguments = xml_tag(instance, "arguments")
    parameters = xml_tag(elem, "interface-parameters")
    instance_name = elem.getAttribute("name")
    def_name = idef.getAttribute("qname")
    fullname = idef.getAttribute("nicename")

    sig = 'interface <a href="../ihtml/%s.html">%s</a>' % (fullname, def_name)
    if arguments:
      iargs = join(map(lambda (arg): typename_str(arg, ""),
                       xml_elements(arguments)), ", ")
      sig += "&lt;" + iargs + "&gt;"
    if instance_name != def_name:
      sig += " as <b>%s</b>" % instance_name
    if parameters:
      iparms = join(map(lambda (arg): typename_str(arg, ""),
                        xml_elements(parameters)),  ", ")
      sig += "[" + iparms + "]"
    ht.p(sig)

# Output HTML for specification elements elems, with heading name
# If elems list is empty, do nothing.
def generate_speclist(ht, name, elems):
  if len(elems) > 0:
    ht.heading(name)
    ht.pushln("ul");
    for elem in elems:
      ht.tag("p")
      ht.tag("li")
      spec_signature_html(ht, elem)
      doc = nd_doc_short(elem)
      if doc != None:
        ht.push("menu")
        ht.pln(doc)
        ht.popln()
    ht.popln()

def generate_component(comp):
  nicename = comp.getAttribute("nicename")
  ht = Html("chtml/%s.html" % nicename )
  if xml_tag(comp, "module"):
    kind = "module"
  else:
    kind = "configuration"
  ht.title("Component: " + nicename)
  ht.body()
  ht.push("h2");
  ht.p("Component: " + nicename)
  ht.popln();
  
  # The source code name and documentation
  ht.push("b")
  parameters = xml_tag(comp, "parameters")
  if parameters:
    ht.p("generic ")
  ht.p(kind + " " + comp.getAttribute("qname"))
  if parameters:
    ht.p(parameter_str(parameters))
  ht.pop()
  ht.startline()
  idoc =  nd_doc_long(comp)
  if idoc != None:
    ht.tag("p")
    ht.pdoc(idoc)
  ht.tag("p")

  spec = xml_tag(comp, "specification")
  interfaces = spec.getElementsByTagName("interface")
  functions = spec.getElementsByTagName("function")
  spec = interfaces + functions
  provided = filter(lambda (x): x.getAttribute("provided") == "1", spec)
  used = filter(lambda (x): x.getAttribute("provided") == "0", spec)
  generate_speclist(ht, "Provides", provided)
  generate_speclist(ht, "Uses", used)

  # wiring graph for configurations
  if xml_tag(comp, "configuration"):
    ht.heading("Wiring")
    ht.pushln("map", 'name="comp"')
    cmap = file("chtml/%s.cmap" % nicename)
    for line in cmap.readlines():
      ht.pln(line)
    cmap.close()
    ht.popln()
    ht.tag("img", 'src="%s.gif"' % nicename, 'usemap="#comp"')
  ht.close()
