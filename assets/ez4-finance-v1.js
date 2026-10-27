(()=>{
  const root=document.querySelector("[data-ez4-finance]");
  if(!root)return;

  const price=Number(root.dataset.price);
  const rateForMonths=months=>months<=6?.08:months<=12?.15:.23;
  const format=new Intl.NumberFormat("en-US",{maximumFractionDigits:0});
  const down=root.querySelector("[data-down]");
  const downPercent=root.querySelector("[data-down-percent]");
  const downAmount=root.querySelector("[data-down-amount]");
  const monthly=root.querySelector("[data-monthly]");
  const totalDebt=root.querySelector("[data-total-debt]");
  const debtLabel=root.querySelector("[data-debt-label]");
  const installmentTotal=root.querySelector("[data-installment-total]");
  const installmentTotalLabel=root.querySelector("[data-installment-total-label]");
  const internalTerms=root.querySelector("[data-internal-terms]");
  const bankTermWrap=root.querySelector("[data-bank-term-wrap]");
  const bankTerm=root.querySelector("[data-bank-term]");
  const bankTermValue=root.querySelector("[data-bank-term-value]");
  const internalPolicy=root.querySelector("[data-internal-policy]");
  const internalNote=root.querySelector("[data-internal-note]");
  const bankNote=root.querySelector("[data-bank-note]");
  const internalEligibility=root.querySelector("[data-eligibility-internal]");
  const bankEligibility=root.querySelector("[data-eligibility-bank]");
  const modeButtons=[...root.querySelectorAll("[data-finance-mode]")];
  const termButtons=[...root.querySelectorAll("[data-term]")];
  const labels={internal:debtLabel.textContent,bank:root.dataset.bankDebtLabel};
  let mode="internal";
  let term=18;

  const toggle=(node,hidden)=>node.classList.toggle("is-hidden",hidden);
  const update=()=>{
    const percent=Number(down.value);
    const paid=price*percent/100;
    const balance=price-paid;
    const months=mode==="internal"?term:Number(bankTerm.value);
    const debt=balance*(1+rateForMonths(months));
    downPercent.textContent=percent;
    downAmount.textContent=format.format(paid);
    monthly.textContent=format.format(debt/months);
    totalDebt.textContent=format.format(debt);
    installmentTotal.textContent=format.format(paid+debt);
    installmentTotalLabel.textContent=mode==="bank"?root.dataset.bankTotalLabel:root.dataset.internalTotalLabel;
    debtLabel.textContent=labels[mode];
    bankTermValue.textContent=bankTerm.value;
  };

  modeButtons.forEach(button=>button.addEventListener("click",()=>{
    mode=button.dataset.financeMode;
    modeButtons.forEach(item=>{
      const active=item===button;
      item.classList.toggle("is-active",active);
      item.setAttribute("aria-pressed",String(active));
    });
    const bank=mode==="bank";
    down.min=bank?"10":"40";
    down.value=bank?"10":"40";
    toggle(internalTerms,bank);
    toggle(bankTermWrap,!bank);
    toggle(internalPolicy,bank);
    toggle(internalNote,bank);
    toggle(bankNote,!bank);
    toggle(internalEligibility,bank);
    toggle(bankEligibility,!bank);
    update();
  }));

  termButtons.forEach(button=>button.addEventListener("click",()=>{
    term=Number(button.dataset.term);
    termButtons.forEach(item=>item.classList.toggle("is-active",item===button));
    update();
  }));
  down.addEventListener("input",update);
  bankTerm.addEventListener("input",update);
  update();
})();
