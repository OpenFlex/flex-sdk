/*

   Licensed to the Apache Software Foundation (ASF) under one or more
   contributor license agreements.  See the NOTICE file distributed with
   this work for additional information regarding copyright ownership.
   The ASF licenses this file to You under the Apache License, Version 2.0
   (the "License"); you may not use this file except in compliance with
   the License.  You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.

 */
package org.apache.flex.forks.batik.ext.awt.image.spi;

import java.awt.image.RenderedImage;
import java.io.IOException;
import java.io.OutputStream;

/**
 * Interface which allows image library independent image writing.
 *
 * @version $Id: ImageWriter.java 478276 2006-11-22 18:33:37Z dvholten $
 */
public interface ImageWriter {

    void writeImage(RenderedImage image, OutputStream out)
            throws IOException;

    void writeImage(RenderedImage image, OutputStream out,
            ImageWriterParams params)
            throws IOException;

    String getMIMEType();

}
