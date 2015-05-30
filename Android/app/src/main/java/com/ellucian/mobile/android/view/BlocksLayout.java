/*
 * Copyright 2015 Ellucian Company L.P. and its affiliates.
 */

package com.ellucian.mobile.android.view;
 
import android.content.Context;
import android.util.AttributeSet;
import android.util.Log;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ScrollView;

import com.ellucian.elluciango.R;
import com.ellucian.mobile.android.util.Utils;



/**
 * Custom layout that contains and organizes a {@link TimeRulerView} and several
 * instances of {@link BlockView}. Also positions current "now" divider using
 * {@link R.id#blocks_now} view when applicable.
 */
public class BlocksLayout extends ViewGroup {

    private TimeRulerView mRulerView;

    public BlocksLayout(Context context) {
        this(context, null);
    }

    public BlocksLayout(Context context, AttributeSet attrs) {
        this(context, attrs, 0);
    }

    public BlocksLayout(Context context, AttributeSet attrs, int defStyle) {
        super(context, attrs, defStyle);
    }

    private void ensureChildren() {
        mRulerView = (TimeRulerView) findViewById(R.id.courses_daily_ruler);
        if (mRulerView == null) {
            throw new IllegalStateException("Must include a R.id.courses_daily_ruler view.");
        }
        mRulerView.setDrawingCacheEnabled(true);
    }

    /**
     * Remove any {@link BlockView} instances, leaving only
     * {@link TimeRulerView} remaining.
     */
    public void removeAllBlocks() {
        ensureChildren();
        removeAllViews();
        addView(mRulerView);
        
    }

    public void addBlock(BlockView blockView) {
        blockView.setDrawingCacheEnabled(true);
        addView(blockView, 1);
    }

    @Override
    protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
        ensureChildren();

        mRulerView.measure(widthMeasureSpec, heightMeasureSpec);
       
        final int width = mRulerView.getMeasuredWidth();
        final int height = mRulerView.getMeasuredHeight();

        setMeasuredDimension(resolveSize(width, widthMeasureSpec),
                resolveSize(height, heightMeasureSpec));
        Log.d("BlocksLayout", "width: " + width + " height: " + height + " getWidth(): " + getWidth() + " getHeight(): " + getHeight());
    }

    @Override
    protected void onLayout(boolean changed, int l, int t, int r, int b) {
        ensureChildren();

        final TimeRulerView rulerView = mRulerView;
        final int headerWidth = rulerView.getHeaderWidth();
        final int columnWidth = (getWidth() - headerWidth);

        rulerView.layout(0, 0, getWidth(), getHeight());

        
        final int count = getChildCount();
        int min = rulerView.getHeight();
        if(count == 1) { //ruler view is a child, so 1 is no blocks on the schedule
        	min = 0;
        }
        
        for (int i = 0; i < count; i++) {
            final View child = getChildAt(i);
            if (child.getVisibility() == GONE) continue;

            if (child instanceof BlockView) {
                final BlockView blockView = (BlockView) child;
                blockView.setBackgroundColor(Utils.getAccentColor(getContext()));
                final int top = rulerView.getTimeVerticalOffset(blockView.getStartTime());
                final int bottom = rulerView.getTimeVerticalOffset(blockView.getEndTime());
                final int left = mRulerView.mHeaderWidth;
                final int right = left + columnWidth;
                child.layout(left, top, right, bottom);
                min = Math.min(min, top);
                
                Log.d("BlockView", "top: " + top + " bottom: " + bottom + " left: " + left + " right: " + right);
            }

        }
        
        if (this.getParent() instanceof ScrollView) {
        	ScrollView sv = (ScrollView)getParent();
        	sv.scrollTo(0, min);
        }
    }
}
