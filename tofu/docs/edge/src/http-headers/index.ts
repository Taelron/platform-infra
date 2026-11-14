// Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

import { CloudFrontResponseHandler } from "aws-lambda";
import * as common from "../shared/shared";

const CONFIG = common.getConfigWithHeaders();
CONFIG.logger.debug("Configuration loaded:", CONFIG);

export const handler: CloudFrontResponseHandler = async (event) => {
  CONFIG.logger.debug("Event:", event);
  const { request, response } = event.Records[0].cf;
  Object.assign(response.headers, CONFIG.cloudFrontHeaders);
  // Taelron Docs: the denied page answers 403, also when check-auth served it
  // in place of a refused space.
  if (request.uri.startsWith("/denied/") && response.status === "200") {
    response.status = "403";
    response.statusDescription = "Forbidden";
  }
  CONFIG.logger.debug("Returning response:\n", JSON.stringify(response));
  return response;
};
