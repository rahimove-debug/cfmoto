(()=>{
  const root=document.querySelector("[data-500sr-colors]");
  if(!root)return;
  const image=document.querySelector("[data-500sr-color-image]");
  const name=root.querySelector("[data-500sr-color-name]");
  const buttons=[...root.querySelectorAll("[data-500sr-color-button]")];
  buttons.forEach(button=>button.addEventListener("click",()=>{
    image.onerror=()=>{
      image.onerror=null;
      image.src="/models/500sr.webp";
      image.alt="500SR — Galaxy Grey rəngi";
      name.textContent="Galaxy Grey";
      buttons.forEach((item,index)=>{
        const active=index===0;
        item.classList.toggle("active",active);
        item.setAttribute("aria-pressed",String(active));
      });
    };
    image.src=button.dataset.image;
    image.alt=button.dataset.alt;
    name.textContent=button.dataset.name;
    buttons.forEach(item=>{
      const active=item===button;
      item.classList.toggle("active",active);
      item.setAttribute("aria-pressed",String(active));
    });
  }));
})();
