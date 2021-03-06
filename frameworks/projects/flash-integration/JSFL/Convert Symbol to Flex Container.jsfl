/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// This script does the following:
// 
// 1. Calls the "Make Flex Component" command
//
// 2. Creates a "FlexContent" symbol that uses FlexContentHolder as a base class
//    

var doc = null;

function getSymbol(name) {
	// search library for specified item
	var items = doc.library.items;
	for (var i = 0; i < items.length; i++) {
		var shortName = items[i].name;
		var slashIndex = shortName.lastIndexOf("/");
		if (slashIndex >= 0) {
			shortName = shortName.substr(slashIndex + 1);
		}
		if (shortName == name) {
			return items[i];
		}
	}

	return null;
}

function createFlexContentSymbol() {
	var flexContentSymbol = getSymbol("FlexContentHolder");

	// If the symbol already exists, there is nothing more to do...
	if (flexContentSymbol != null)
		return true;

	var holderDoc = fl.openDocument(fl.configURI + "Libraries/ContentHolder.fla");
	var copiedSymbol = false;

	if (holderDoc) {
		holderDoc.library.addItemToDocument({x:0, y:0}, "FlexContentHolder");
		holderDoc.clipCopy();
		holderDoc.close(false);
		copiedSymbol = true;
	}

	if (copiedSymbol) {
		doc.clipPaste();
		doc.deleteSelection();

		flexContentSymbol = getSymbol("FlexContentHolder");

		if (flexContentSymbol != null)
		{
			flexContentSymbol.linkageExportForAS = true;
			flexContentSymbol.linkageExportInFirstFrame = true;
			flexContentSymbol.linkageBaseClass = "mx.flash.FlexContentHolder";
			
			// the randomness gives the classname a unique ID so that a unique class name can 
			// map to this instance of the FlexContentHolder and multiple swcs can co-exist peacefully
			flexContentSymbol.linkageClassName = "FlexContentHolder" + Math.random().toString().substring(2);

			return true;
		}
	}

	return false;
}

// Main execution starts here
doc = fl.getDocumentDOM();

if (fl.runScript(fl.configURI + 'Javascript/MakeFlexComponent.jsfl', 'makeFlexComponent', 'mx.flash.ContainerMovieClip',
 		'Add the \'FlexContentHolder\' symbol to define the Flex content area.'))
	createFlexContentSymbol()
