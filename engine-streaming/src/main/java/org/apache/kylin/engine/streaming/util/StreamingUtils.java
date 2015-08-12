/*
 *
 *
 *  Licensed to the Apache Software Foundation (ASF) under one or more
 *
 *  contributor license agreements. See the NOTICE file distributed with
 *
 *  this work for additional information regarding copyright ownership.
 *
 *  The ASF licenses this file to You under the Apache License, Version 2.0
 *
 *  (the "License"); you may not use this file except in compliance with
 *
 *  the License. You may obtain a copy of the License at
 *
 *
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *
 *
 *  Unless required by applicable law or agreed to in writing, software
 *
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 *  See the License for the specific language governing permissions and
 *
 *  limitations under the License.
 *
 * /
 */
package org.apache.kylin.engine.streaming.util;

import com.google.common.base.Preconditions;
import org.apache.kylin.common.KylinConfig;
import org.apache.kylin.common.util.ClassUtil;
import org.apache.kylin.engine.streaming.*;
import org.apache.kylin.engine.streaming.cube.StreamingCubeBuilder;

/**
 */
public class StreamingUtils {
    
    public static IStreamingInput getStreamingInput(String streaming) {
        return (IStreamingInput) ClassUtil.newInstance("org.apache.kylin.source.kafka.KafkaStreamingInput");
    }
    
    public static IStreamingOutput getStreamingOutput(String streaming) {
        return (IStreamingOutput) ClassUtil.newInstance("org.apache.kylin.storage.hbase.HBaseStreamingOutput");
    }
    
    public static StreamingBatchBuilder getMicroBatchBuilder(String streaming) {
        final StreamingConfig streamingConfig = StreamingManager.getInstance(KylinConfig.getInstanceFromEnv()).getStreamingConfig(streaming);
        Preconditions.checkNotNull(streamingConfig);
        if (streamingConfig.getCubeName() != null) {
            return new StreamingCubeBuilder(streamingConfig.getCubeName());
        } else if (streamingConfig.getIiName() != null) {
            throw new UnsupportedOperationException("not implemented yet");
        } else {
            throw new UnsupportedOperationException("StreamingConfig is not valid");
        }
    }
}