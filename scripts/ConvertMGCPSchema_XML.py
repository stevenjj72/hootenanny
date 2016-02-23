#!/usr/bin/python

# Parse the MGCP XML into a schema
import sys,argparse,gzip
from xml.dom import minidom

# Start printJavascript
def printJSHeader(fileName):
    print notice
    print
    print '//  Schema built from %s' % (fileName)
    print
    print "var _global = (0, eval)('this');"
    print 'if (!_global.mgcp)'
    print '{'
    print '  _global.mgcp = {};'
    print '}'
    print
    print 'mgcp.schema = {'
    print 'getDbSchema: function()'
    print '{'
# End printJSHeader


# printJavascript: Dump out the structure as Javascript
#
# Note: This uses double quotes ( " ) around data elements in the output.  The csv files have values with
# single quotes ( ' ) in them.  These quotes are also in the DFDD and NFDD specs.
def printJavascript(schema):
    print '    var schema = [' # And so it begins...

    num_feat = len(schema.keys()) # How many features in the schema?
    for f in sorted(schema.keys()):
        # Skip all of the 'Table' features
        if schema[f]['geom'] == 'Table':
            continue

        print '        { name:"%s",' % (f); # name = geom + FCODE
        print '          fcode:"%s",' % (schema[f]['fcode'])
        print '          desc:"%s",' % (schema[f]['desc'])
        print '          geom:"%s",' % (schema[f]['geom'])
        print '          columns:[ '

        num_attrib = len(schema[f]['columns'].keys()) # How many attributes does the feature have?
        for k in sorted(schema[f]['columns'].keys()):
            print '                     { name:"%s",' % (k)
            print '                       desc:"%s" ,' % (schema[f]['columns'][k]['desc'])
            print '                       optional:"%s" ,' % (schema[f]['columns'][k]['optional'])

            #if schema[f]['columns'][k]['length'] != '':
            if 'length' in schema[f]['columns'][k]:
                print '                       length:"%s", ' % (schema[f]['columns'][k]['length'])

            #if schema[f]['columns'][k]['type'].find('numeration') != -1:
            if 'func' in schema[f]['columns'][k]:
                print '                       type:"enumeration",'
                print '                       defValue:"%s", ' % (schema[f]['columns'][k]['defValue'])
                print '                       enumerations: %s' % (schema[f]['columns'][k]['func'])

            elif schema[f]['columns'][k]['type'] == 'enumeration':
                #print '                       type:"%s",' % (schema[f]['columns'][k]['type'])
                print '                       type:"enumeration",'
                print '                       defValue:"%s", ' % (schema[f]['columns'][k]['defValue'])
                print '                       enumerations:['
                for l in schema[f]['columns'][k]['enum']:
                    print '                           { name:"%s", value:"%s" }, ' % (l['name'],l['value'])
                print '                        ] // End of Enumerations '

            #elif schema[f]['columns'][k]['type'] == 'textEnumeration':
                #print '                       type:"Xenumeration",'
                #print '                       defValue:"%s", ' % (schema[f]['columns'][k]['defValue'])
                #print '                       enumerations: text_%s' % (k)

            else:
                print '                       type:"%s",' % (schema[f]['columns'][k]['type'])
                print '                       defValue:"%s" ' % (schema[f]['columns'][k]['defValue'])

            if num_attrib == 1:  # Are we at the last attribute? yes = no trailing comma
                print '                     } // End of %s' % (k)
            else:
                print '                     }, // End of %s' % (k)
                num_attrib -= 1

        print '                    ] // End of Columns'

        if num_feat == 1: # Are we at the last feature? yes = no trailing comma
            print '          } // End of feature %s\n' % (schema[f]['fcode'])
        else:
            print '          }, // End of feature %s\n' % (schema[f]['fcode'])
            num_feat -= 1

    print '    ]; // End of schema\n' # End of schema
# End printJavascript


def printJSFooter():
    print '    return schema; \n'
    print '} // End of getDbSchema\n'
    print '} // End of mgcp.schema\n'
    print
    print 'exports.getDbSchema = mgcp.schema.getDbSchema;'
    print
# End printJSFooter

# Data & Lists
notice = """/*
 * This file is part of Hootenanny.
 *
 * Hootenanny is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * --------------------------------------------------------------------
 *
 * The following copyright notices are generated automatically. If you
 * have a new notice to add, please use the format:
 * " * @copyright Copyright ..."
 * This will properly maintain the copyright information. DigitalGlobe
 * copyrights will be updated automatically.
 *
 * @copyright Copyright (C) 2012, 2013 DigitalGlobe (http://www.digitalglobe.com/)
 */

 ////
 // This file is automatically generated. Please do not modify the file
 // directly.
 ////
 """


# XML Functions
# Text Node
def processText(node):
    tlist = node.getElementsByTagName('gco:CharacterString')
    #print 'Definition:', tlist[0].firstChild.data
    return tlist[0].firstChild.data
# End Text Node

# Generic single node
def processSingleNode(node,text):
    tlist = node.getElementsByTagName(text)
    #print 'Feature Type:', tlist[0].firstChild.data
    return tlist[0].firstChild.data
# End typeName


def processFile(fileName):
    xmlDoc = minidom.parse(fileName)

    #itemList = xmlDoc.getElementsByTagName('gfc:featureType')
    itemList = xmlDoc.getElementsByTagName('gfc:FC_FeatureType')

    print 'Items: ', len(itemList)

    # Setup
    geoList = {'L':'Line', 'A':'Area', 'P':'Point','_':'None' }
    typeList = {'CodeList':'enumeration','CharacterString':'String','Real':'Real','Integer':'Integer',
                'GM_Surface':'none', 'GM_Curve':'none','GM_Point':'none' }
    tSchema = {}

    for feature in itemList:
        rawfCode = feature.getAttribute('id')

        #if rawfCode == '_GMGCP':
            #continue

        #if rawfCode != 'AAA010':
            #continue

        fGeometry = geoList[rawfCode[0]]
        print 'Geometry: ', fGeometry
        fCode = rawfCode[1:]
        print 'FCODE: ', fCode

        # Build a feature
        if rawfCode not in tSchema:
            tSchema[rawfCode] = {}
            tSchema[rawfCode]['name'] = rawfCode
            tSchema[rawfCode]['fcode'] = fCode
            tSchema[rawfCode]['geom'] = fGeometry
            tSchema[rawfCode]['columns'] = {}
            tSchema[rawfCode]['columns']['F_CODE'] = { 'name':'F_CODE','desc':"Feature Code",'type':'String','optional':'R','defValue':'','length':'5'}


        for node in feature.childNodes:
            if not node.localName:
                continue
            #else:
                #print 'localName: ', node.localName

            if node.localName == 'isAbstract':
                print 'Abstract: ', processSingleNode(node,'gco:Boolean')
                continue

            if node.localName == 'featureCatalogue':
                continue

            # The short version f the feature definition
            if node.localName == 'typeName':
                #print 'Feature Type: ', processSingleNode(node,'gco:LocalName')
                tSchema[rawfCode]['desc'] = processSingleNode(node,'gco:LocalName')
                continue

            # The long version of the feature definition
            if node.localName == 'definition':
                #print 'Definition: ', processText(node)
                continue

            # Loop through the feature attributes
            if node.localName == 'carrierOfCharacteristics':
                aName = ''
                aDesc = ''
                aType = ''
                aDefVal = ''
                aLength = ''
                aEnum = []

                for attribute in node.getElementsByTagName('gfc:FC_FeatureAttribute')[0].childNodes:
                    if not attribute.localName:
                        continue
                    #else:
                        #print 'Attr: ', attribute.localName

                    if attribute.localName == 'cardinality':
                        continue

                    if attribute.localName == 'featureType':
                        continue

                    if attribute.localName == 'memberName':
                        print 'attr Name Def: ', processSingleNode(attribute,'gco:LocalName')
                        aDesc = processSingleNode(attribute,'gco:LocalName')
                        continue

                    if attribute.localName == 'definition':
                        #print 'attr Def: ', processText(attribute)
                        continue

                    if attribute.localName == 'definitionReference':
                        print 'attr Name: ', processText(attribute)
                        aName = processText(attribute)
                        continue

                    if attribute.localName == 'valueType':
                        print 'attr Type: ', processText(attribute)
                        aType = typeList[processText(attribute)]

                        if aType == 'String':
                            aDefVal = 'UNK'
                        if aType == 'Real':
                            aDefVal = '-32767.0'
                        if aType == 'Integer':
                            aDefVal = '-32767'

                        continue

                    if attribute.localName == 'constrainedBy':
                        #print 'attr Constraint: ', processText(attribute)
                        # Constraint is something like: "0 to 100 Characters"
                        aLength = processText(attribute).split()[2]
                        continue

                    if attribute.localName == 'listedValue':
                        lName = ''
                        lValue = ''
                        for listed in attribute.getElementsByTagName('gfc:FC_ListedValue')[0].childNodes:
                            if not listed.localName:
                                continue
                            #else:
                                #print 'Listed Attr: ', listed.localName

                            if listed.localName == 'label':
                                print 'Listed Label: ', processText(listed)
                                lName = processText(listed)
                                continue

                            if listed.localName == 'code':
                                print 'Listed Code: ', processText(listed)
                                lValue = processText(listed)
                                continue

                            if listed.localName == 'definition':
                                #print 'Listed Def: ', processText(listed)
                                continue

                            if listed.localName == 'definitionReference':
                                #print 'Listed Name: ', processText(listed)
                                continue
                            print '##### Listed Missed ', listed.localName

                        aEnum.append({'name':lName,'value':lValue})
                        continue


                    print '##### Carrier Missed ', attribute.localName

                # Now build a feature
                if aType != 'none':
                    tSchema[rawfCode]['columns'][aName] = {}
                    tSchema[rawfCode]['columns'][aName] = { 'name':aName,
                                                            'desc':aDesc,
                                                            'type':aType,
                                                            'defValue':aDefVal,
                                                            'optional':'R'
                                                          }
                    if aLength != '':
                        tSchema[rawfCode]['columns'][aName]['length'] = aLength

                    if aType == 'enumeration':
                        tSchema[rawfCode]['columns'][aName]['enum'] = []
                        tSchema[rawfCode]['columns'][aName]['enum'] = aEnum

                print '------------------------------------------------'
                continue

            print '##### Node Missed ', node.localName

    return tSchema
# End of processFile


###########
# Main Starts Here
#
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Process XML Schema file and build a schema')
    parser.add_argument('-q','--quiet', help="Don't print warning messages.",action='store_true')
    parser.add_argument('--rules', help='Dump out one2one rules',action='store_true')
    parser.add_argument('--txtrules', help='Dump out text rules',action='store_true')
    parser.add_argument('--numrules', help='Dump out number rules',action='store_true')
    parser.add_argument('--attrlist', help='Dump out a list of attributes',action='store_true')
    parser.add_argument('--fcodelist', help='Dump out a list of attributes',action='store_true')
    parser.add_argument('--toenglish', help='Dump out To English translation rules',action='store_true')
    parser.add_argument('--fromenglish', help='Dump out From English translation rules',action='store_true')
    parser.add_argument('--attributecsv', help='Dump out attributes as a CSV file',action='store_true')
    parser.add_argument('--txtlength', help='Dump out the lengths of the text elements',action='store_true')
    parser.add_argument('--fullschema', help='Dump out a schema with text enumerations',action='store_true')
    parser.add_argument('xmlFile', help='The XML Schema file', action='store')

    args = parser.parse_args()

    #xmlDoc = minidom.parse('MGCP_FeatureCatalogue_TRD4_v4.1_20130628.xml')
    schema = {}
    schema = processFile(args.xmlFile)

    printJSHeader(args.xmlFile)
    printJavascript(schema)
    printJSFooter()

