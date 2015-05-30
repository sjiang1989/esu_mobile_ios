/*
 * Copyright 2015 Ellucian Company L.P. and its affiliates.
 */

package com.ellucian.mobile.android.app;

import android.content.Context;
import android.support.v7.widget.RecyclerView;
import android.util.AttributeSet;
import android.util.Log;
import android.view.View;

import com.ellucian.mobile.android.adapter.EllucianRecyclerAdapter;

/**
 * Created by jhigley on 2/11/15.
 */
public class EllucianRecyclerView extends RecyclerView {

    protected int selectedIndex = -1;

    public EllucianRecyclerView(Context context) {
        super(context);
    }

    public EllucianRecyclerView(Context context, AttributeSet attrs) {
        super(context, attrs);
    }

    public EllucianRecyclerView(Context context, AttributeSet attrs, int defStyle) {
        super(context, attrs, defStyle);
    }

    public int getSelectedIndex() {
        return selectedIndex;
    }

    public void setSelectedIndex(int index) {
        selectedIndex = index;

        if (getAdapter() != null) {
            ((EllucianRecyclerAdapter)getAdapter()).setSelectedIndex(index);
        }
    }

    public void clearSelected() {
        selectedIndex = -1;

        if (getAdapter() != null) {
            ((EllucianRecyclerAdapter)getAdapter()).clearSelected();
        }
    }
}
