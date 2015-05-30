/*
 * Copyright 2015 Ellucian Company L.P. and its affiliates.
 */

package com.ellucian.mobile.android.client.services;

import android.app.IntentService;
import android.content.ContentProviderOperation;
import android.content.Intent;
import android.content.OperationApplicationException;
import android.os.RemoteException;
import android.support.v4.content.LocalBroadcastManager;
import android.text.TextUtils;
import android.util.Log;

import com.ellucian.mobile.android.client.MobileClient;
import com.ellucian.mobile.android.client.courses.assignments.CourseAssignmentsBuilder;
import com.ellucian.mobile.android.client.courses.assignments.CourseAssignmentsResponse;
import com.ellucian.mobile.android.provider.EllucianContract;
import com.ellucian.mobile.android.util.Extra;

import java.util.ArrayList;

public class CourseAssignmentsIntentService extends IntentService {
	public static final String TAG = CourseAssignmentsIntentService.class.getSimpleName();
	public static final String PARAM_OUT_DATABASE_UPDATED = "updated";
	public static final String ACTION_FINISHED = "com.ellucian.mobile.android.client.services.CourseAssignmentsIntentService.action.updated";
	
	public CourseAssignmentsIntentService() {
		super("CourseAssignmentsIntentService");
	}

	@Override
	protected void onHandleIntent(Intent intent) {
		boolean success = false;
		Log.d(TAG, "handling intent");
		MobileClient client = new MobileClient(this);

        client.setSendUnauthenticatedBroadcast(intent.getBooleanExtra(Extra.SEND_BROADCAST, true));
		String url = client.addUserToUrl(intent.getStringExtra(Extra.COURSES_ILP_URL));

		String courseId = intent.getStringExtra(Extra.COURSES_COURSE_ID);
        String termId = intent.getStringExtra(Extra.COURSES_TERM_ID);

		if(!TextUtils.isEmpty(courseId) && !TextUtils.isEmpty(termId)) {
			url += "/" + courseId + "/assignments?term=" + termId;
		} else {
			url += "/assignments";
		}
		CourseAssignmentsResponse response = client.getCourseAssignments(url);
		
		if (response != null) {
			Log.d(TAG, "Retrieved response from client");
			CourseAssignmentsBuilder builder = new CourseAssignmentsBuilder(this, courseId);
			Log.d(TAG, "Building content provider operations");
			ArrayList<ContentProviderOperation> ops = builder.buildOperations(response);
			Log.d(TAG, "Created " + ops.size() + " operations");
			
			if(ops.size() > 0) {
				Log.d(TAG, "Executing batch.");
				try {
					getContentResolver().applyBatch(
							EllucianContract.CONTENT_AUTHORITY, ops);
					success = true;
				} catch (RemoteException e) {
					Log.e(TAG, "RemoteException applying batch" + e.getLocalizedMessage());
				} catch (OperationApplicationException e) {
					Log.e(TAG, "OperationApplicationException applying batch:" + e.getLocalizedMessage());
				}
				Log.d(TAG, "Batch executed.");
				
				LocalBroadcastManager bm = LocalBroadcastManager.getInstance(this);
				Intent broadcastIntent = new Intent();
				broadcastIntent.setAction(ACTION_FINISHED);
				broadcastIntent.putExtra(PARAM_OUT_DATABASE_UPDATED, success);
				bm.sendBroadcast(broadcastIntent);
			}
		} else {
			Log.d(TAG, "Response Object was null");
		}

	}

}
