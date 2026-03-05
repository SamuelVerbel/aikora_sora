// SCROLL SUAVE
document.querySelectorAll("a[href^='#']").forEach(anchor => {

  anchor.addEventListener("click", function(e){

    e.preventDefault()

    document.querySelector(this.getAttribute("href"))
      .scrollIntoView({
        behavior:"smooth"
      })

  })

})


// NAVBAR DINAMICA

const nav = document.querySelector(".nav")

window.addEventListener("scroll",()=>{

  if(window.scrollY>40){

    nav.classList.add("nav-scrolled")

  }else{

    nav.classList.remove("nav-scrolled")

  }

})


// REVEAL ANIMATION

const elements = document.querySelectorAll(
  ".feature-card, .screen-card, .step, .tech-card"
)

const observer = new IntersectionObserver(entries=>{

  entries.forEach(entry=>{

    if(entry.isIntersecting){

      entry.target.classList.add("reveal")

    }

  })

})

elements.forEach(el=>observer.observe(el))