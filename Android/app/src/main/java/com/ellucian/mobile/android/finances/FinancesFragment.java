/*
 * Copyright 2015 Ellucian Company L.P. and its affiliates.
 */

package com.ellucian.mobile.android.finances;

import android.app.Activity;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.net.Uri;
import android.os.Bundle;
import android.support.v4.content.LocalBroadcastManager;
import android.text.TextUtils;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.ListView;
import android.widget.TextView;

import com.ellucian.elluciango.R;
import com.ellucian.mobile.android.app.EllucianFragment;
import com.ellucian.mobile.android.app.GoogleAnalyticsConstants;
import com.ellucian.mobile.android.client.finances.BalanceTerm;
import com.ellucian.mobile.android.client.finances.BalancesResponse;
import com.ellucian.mobile.android.client.finances.Transaction;
import com.ellucian.mobile.android.client.finances.TransactionTerm;
import com.ellucian.mobile.android.client.finances.TransactionsResponse;
import com.ellucian.mobile.android.client.services.FinancesBalanceIntentService;
import com.ellucian.mobile.android.client.services.FinancesTransactionsIntentService;
import com.ellucian.mobile.android.util.CurrencyUtils;
import com.ellucian.mobile.android.util.Extra;
import com.ellucian.mobile.android.util.Utils;
import com.ellucian.mobile.android.webframe.WebframeActivity;

import java.util.Arrays;
import java.util.Collections;
import java.util.Currency;

public class FinancesFragment extends EllucianFragment {

    private View rootView;
    private TextView balanceView;
    private ListView transactionsView;
    private Button buttonView;
    private String buttonText;
    private String buttonUrl;
    private Boolean useExternalBrowser;
    private FinancesActivity financesActivity;
    private BalanceReceiever balanceReceiever;
    private TransactionsReceiever transactionsReceiever;
    public static final String PROXY_TERM_ID = "MOBILESERVER_PROXY_TERM_ID";
    public static final String TAG = "FinancesFragment";

    @Override
    public void onAttach(Activity activity) {
        super.onAttach(activity);
        financesActivity = (FinancesActivity) activity;
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setRetainInstance(true);

        Intent transactionsIntent = new Intent(financesActivity, FinancesTransactionsIntentService.class);
        transactionsIntent.putExtra(Extra.REQUEST_URL, getArguments().getString(Extra.REQUEST_URL));
        financesActivity.startService(transactionsIntent);

        Intent balanceIntent = new Intent(financesActivity, FinancesBalanceIntentService.class);
        balanceIntent.putExtra(Extra.REQUEST_URL, getArguments().getString(Extra.REQUEST_URL));
        financesActivity.startService(balanceIntent);

        buttonText = getArguments().getString(Extra.LINK_LABEL);
        buttonUrl = getArguments().getString(Extra.LINK);
        useExternalBrowser = getArguments().getBoolean(Extra.LINK_EXTERNAL_BROWSER);
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        if (rootView == null) {
            rootView = inflater.inflate(R.layout.fragment_finances, container, false);
            balanceView = (TextView) rootView.findViewById(R.id.balance_text_view);
            TextView dividerBar = (TextView) rootView.findViewById(R.id.finances_divider_bar);
            dividerBar.setBackgroundColor(Utils.getAccentColor(financesActivity));
            dividerBar.setTextColor(Utils.getSubheaderTextColor(financesActivity));
            transactionsView = (ListView) rootView.findViewById(R.id.transactions_list_view);
            transactionsView.setEmptyView(rootView.findViewById(R.id.transactions_no_data));

            buttonView = (Button) rootView.findViewById(R.id.finance_url_button);
            if (!TextUtils.isEmpty(buttonText) && !TextUtils.isEmpty(buttonUrl)) {
                buttonView.setVisibility(View.VISIBLE);
                buttonView.setText(buttonText);
                buttonView.setOnClickListener(new View.OnClickListener() {
                    @Override
                    public void onClick(View v) {

                        sendEventToTracker1(GoogleAnalyticsConstants.CATEGORY_UI_ACTION, GoogleAnalyticsConstants.ACTION_BUTTON_PRESS, "Open financial service", null, getEllucianActivity().moduleName);
                        Intent intent = new Intent();
                        if (useExternalBrowser) {
                            intent = new Intent(Intent.ACTION_VIEW);
                            intent.setData(Uri.parse(buttonUrl));
                        } else {
                            intent.setClass(financesActivity, WebframeActivity.class);
                            intent.putExtra(Extra.REQUEST_URL, buttonUrl);
                            intent.putExtra(Extra.MODULE_NAME, getEllucianActivity().moduleName);
                        }
                        startActivity(intent);
                    }
                });
            } else {
                buttonView.setVisibility(View.GONE);
            }

        }
        return rootView;
    }

    @Override
    public void onStart() {
        super.onStart();
        sendView("View Account Balance", financesActivity.moduleName);
    }

    @Override
    public void onResume() {
        super.onResume();
        LocalBroadcastManager lbm = LocalBroadcastManager.getInstance(financesActivity);
        balanceReceiever = new BalanceReceiever();
        transactionsReceiever = new TransactionsReceiever();
        lbm.registerReceiver(balanceReceiever, new IntentFilter(FinancesBalanceIntentService.ACTION_UPDATE_FINISHED));
        lbm.registerReceiver(transactionsReceiever, new IntentFilter(FinancesTransactionsIntentService.ACTION_UPDATE_FINISHED));
    }

    @Override
    public void onPause() {
        super.onPause();
        LocalBroadcastManager lbm = LocalBroadcastManager.getInstance(financesActivity);
        lbm.unregisterReceiver(balanceReceiever);
        lbm.unregisterReceiver(transactionsReceiever);
    }

    private class BalanceReceiever extends BroadcastReceiver {

        @Override
        public void onReceive(Context context, Intent intent) {
            BalancesResponse balancesResponse = null;
            Boolean success = false;
            balancesResponse = intent.getParcelableExtra(FinancesBalanceIntentService.UPDATE_RESULT);

            if (balancesResponse != null) {
                if (balancesResponse.terms.length > 0) {
                    for (BalanceTerm balanceTerm : balancesResponse.terms) {
                        // Currently, we only expect 1 term in the response, which contains the
                        // overall balance. In the future, the APIs may provide Term specific balances,
                        // similar to how Student Self-Service presents the data. For now, the overall
                        // balance is in termId PROXY_TERM_ID.
                        if (balanceTerm.termId.equals(PROXY_TERM_ID)) {
                            success = true;
                            Double balance = balanceTerm.balance;
                            Currency currency;
                            try {
                                currency = Currency.getInstance(balancesResponse.currencyCode);
                            } catch (Exception e) {
                                Log.e(TAG, "No valid currency found. Default to USD.");
                                currency = Currency.getInstance("USD");
                            }
                            balanceView.setText(CurrencyUtils.getCurrencyString(balance, currency));
                        }
                    }
                }
            }

            if (!success) {
                balanceView.setText(R.string.finances_no_balance);
                balanceView.setTextSize(40);
            }
        }
    }

    private class TransactionsReceiever extends BroadcastReceiver {

        @Override
        public void onReceive(Context context, Intent intent) {
            TransactionsResponse transactionsResponse = null;
            transactionsResponse = intent.getParcelableExtra(FinancesTransactionsIntentService.UPDATE_RESULT);

            if (transactionsResponse != null) {
                if (transactionsResponse.terms.length > 0) {
                    for (TransactionTerm transactionTerm : transactionsResponse.terms) {
                        // Currently, we only expect 1 term in the response, which contains all
                        // recent payment transactions. In the future, the APIs may provide Term specific
                        // transactions, similar to how Self-Service presents the data. For now, the recent
                        // transactions are in termId PROXY_TERM_ID.
                        if (transactionTerm.termId.equals(PROXY_TERM_ID)) {
                            Transaction[]  transactions = transactionTerm.transactions;
                            // Need to sort transactions by descending.
                            Arrays.sort(transactions, Collections.reverseOrder());
                            Currency currency;
                            try {
                                currency = Currency.getInstance(transactionsResponse.currencyCode);
                            } catch (Exception e) {
                                Log.e(TAG, "No valid currency found. Default to USD.");
                                currency = Currency.getInstance("USD");
                            }
                            TransactionsAdapter adapter = new TransactionsAdapter(financesActivity, currency, transactions);
                            // Attach adapter to ListView
                            transactionsView.setAdapter(adapter);
                        }
                    }
                }
            }
        }
    }
}
