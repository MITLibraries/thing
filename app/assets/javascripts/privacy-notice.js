// Creates a cookie to indicate acknowledgment of privacy notice
const setCookie = () => {
  let now = new Date();
  let expiration = new Date(now.setFullYear(now.getFullYear() + 1));
  document.cookie = "mitlibPrivAck=true;domain=.mit.edu;path=/;expires=" + expiration;

  // Remove the privacy notice once the cookie is set
  document.getElementById('privacy-notice').remove();
}

// Fetch privacy notice acknowledgment cookie
const getCookieValue = (cookieName) => {
  // Go no further if cookies are empty
  if (!document.cookie) {
    return null;
  }

  // Split document.cookie into an array
  let cookies = document.cookie.split(';');

  // Initialize this to null so it returns falsey if the value isn't found
  let match = null;

  // Look for the cookie name in the array
  cookies.forEach((element) => {
    let cookiePair = element.split('=');

    if (cookieName == cookiePair[0].trim()) {
      match = decodeURIComponent(cookiePair[1]);
    }
  });

  // Return the cookie value if found (or null otherwise)
  return match;
}

// https://developer.mozilla.org/en-US/docs/Web/API/CSSStyleSheet/insertRule
const addStylesheetRules = (rules) => {
  let styleEl = document.createElement('style');

  // Append <style> element to <head>
  document.head.appendChild(styleEl);

  // Grab style element's sheet
  let styleSheet = styleEl.sheet;

  for (let i = 0; i < rules.length; i++) {
    let j = 1, 
        rule = rules[i], 
        selector = rule[0], 
        propStr = '';
    // If the second argument of a rule is an array of arrays, correct our variables.
    if (Array.isArray(rule[1][0])) {
      rule = rule[1];
      j = 0;
    }

    for (let pl = rule.length; j < pl; j++) {
      let prop = rule[j];
      propStr += prop[0] + ': ' + prop[1] + (prop[2] ? ' !important' : '') + ';\n';
    }

    // Insert CSS Rule
    styleSheet.insertRule(selector + '{' + propStr + '}', styleSheet.cssRules.length);
  }
}

// Display privacy notice if the acknowledgment cookie isn't set
const privacyNotice = () => {
  if (!getCookieValue('mitlibPrivAck')) {
    document.body.innerHTML += `
      <div id="privacy-notice" style="position: fixed; display: flex; justify-content: space-between; align-items: center; margin-bottom: 2rem; border-radius: 2px; padding: 1.2rem 1.6rem; border: 1px solid #000; border-top: 5px solid #000; font-weight: 600; font-size: 16px; font-family: 'Helvetica Neue', Helvetica, Arial, 'Open Sans', sans-serif; background-color: #eee; color: #000; bottom: 40px; left: 10%; right: 10%; width: 80%">
        <span style="margin-right: .5em;">
          <i class="fa fa-info-circle fa-lg" style="display: inline-block; margin-right: .5em"></i>
          By using this website, you consent to the <a href="#" style="transition: all .25s ease-in-out 0s;">MIT Libraries privacy policy</a>.
        </span>
        <button onclick="setCookie();" style="transition: all .25s; height: 80%; border-radius: 3px; padding: 5px 10px; font-size: 16px; font-weight: 600; color: #fff; text-decoration: none; cursor: pointer;">I understand</a></button>
      </div>
    `;
  }
}

window.onload = () => { 
  addStylesheetRules([
    ['#privacy-notice a',
      ['color', '#000'],
      ['text-decoration', 'underline']
    ],
    ['#privacy-notice button',
      ['background-color', '#000'],
      ['border', '1px solid #000']
    ],
    ['#privacy-notice a:hover',
      ['color', '#0000ff'],
      ['text-decoration', 'none']
    ],
    ['#privacy-notice a:focus',
      ['color', '#0000ff'],
      ['text-decoration', 'none']
    ],  
    ['#privacy-notice button:hover', 
      ['background-color', '#0000ff'],
      ['border-color', '#0000ff'],
      ['background-image', 'none']
    ],
    ['#privacy-notice button:focus', 
      ['background-color', '#0000ff'],
      ['border-color', '#0000ff'],
      ['background-image', 'none']
    ]
  ]);
  privacyNotice();
}
