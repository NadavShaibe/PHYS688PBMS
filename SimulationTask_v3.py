import numpy as np
import matplotlib.pyplot as plt

# Initialize
font = 'Times'
Bool = [0, 1]

# Simulation parameters
NW = int(input("Please input desired number of attacking warheads: "))
while NW <= 0:
    print('Number of warheads cannot be negative or 0, try again.')
    NW = int(input("Please input desired number of attacking warheads: "))

Y = float(input("Please input desired yield of the warhead(s) in kt (kilotons of TNT): "))
while Y <= 0:
    print('Yield cannot be negative or 0, try again.')
    Y = float(input("Please input desired yield of the warhead(s) in kt (kilotons of TNT): "))

CEP = float(input("Please input the CEP of the warhead(s) in m (meters): "))
while CEP <= 0:
    print('CEP cannot be negative or 0, try again.')
    CEP = float(input("Please input the CEP of the warhead(s) in m (meters): "))

Interceptors = int(input("If you would like interceptors, press 1; otherwise press 0: "))
while Interceptors not in Bool:
    print('Invalid response, try again.')
    Interceptors = int(input("Please input a 1 (interceptors) or 0 (no interceptors): "))

if Interceptors == 0:
    PI = 0
    NI = 0
    PropTP = 0
    PropFP = 0
    ND = 0
else:
    PI = float(input("Probability (out of 100) of intercepting a warhead: ")) / 100
    while not (0 <= PI <= 1):
        print('Probability of interception must be between 0 and 100.')
        PI = float(input("Probability (out of 100) of intercepting a warhead: ")) / 100

    NI = int(input("How many interceptors should be sent per warhead: "))
    while NI <= 0:
        print('Number of interceptors cannot be negative or 0.')
        NI = int(input("Please input the number of interceptors per warhead: "))

    Decoys = int(input("If you would like decoys, press 1; otherwise press 0: "))
    while Decoys not in Bool:
        print('Invalid response, try again.')
        Decoys = int(input("Please input a 1 (decoys) or 0 (no decoys): "))

    if Decoys == 0:
        PropTP = 1
        PropFP = 0
        ND = 0
    else:
        PropTP = float(input("Probability (out of 100) of a true positive: ")) / 100
        while not (0 <= PropTP <= 1):
            print('Probability of a true positive must be between 0 and 100.')
            PropTP = float(input("Probability (out of 100) of a true positive: ")) / 100

        PropFP = float(input("Probability (out of 100) of a false positive: ")) / 100
        while not (0 <= PropFP <= 1):
            print('Probability of a false positive must be between 0 and 100.')
            PropFP = float(input("Probability (out of 100) of a false positive: ")) / 100

        ND = int(input("How many decoys per warhead: "))
        while ND <= 0:
            print('Number of decoys cannot be negative or 0.')
            ND = int(input("Please input the number of decoys per warhead: "))

H = float(input("Please input hardness of the target in psi: "))
while H <= 0:
    print('Hardness cannot be negative or 0, try again.')
    H = float(input("Please input hardness of the target in psi: "))

# Calculations
LR = 460 * (Y / H) ** (1 / 3)  # Lethal Radius in meters
P_K1 = 1 - 0.5 ** ((LR / CEP) ** 2)  # Probability of kill per warhead

P_W = (PropTP) / (PropTP + PropFP * ND) if PropTP + PropFP * ND != 0 else 0  # Probability of identifying warhead
P_I = (1 - (1 - PI * P_W) ** NI) if P_W != 0 else 0  # Probability of interception

# Simulation and plot setup
theta = np.linspace(0, 2 * np.pi, 1000)
xLR = LR * np.cos(theta)
yLR = LR * np.sin(theta)
xCEP = CEP * np.cos(theta)
yCEP = CEP * np.sin(theta)
radius = 2 * max(CEP, LR)

suc = np.random.rand(NW)
NumIntercepted = np.sum(suc < P_I)
NumPassed = NW - NumIntercepted
inout = np.random.rand(NumPassed)

# Generate random points within the CEP and LR circles
def random_points_within_circle(radius, n_points):
    angles = np.random.uniform(0, 2 * np.pi, n_points)
    radii = radius * np.sqrt(np.random.uniform(0, 1, n_points))
    x_points = radii * np.cos(angles)
    y_points = radii * np.sin(angles)
    return np.column_stack((x_points, y_points))

# Generate hit locations within the circles
hitlocation = np.zeros((NumPassed, 2))
hitlocation[inout < 0.5, :] = random_points_within_circle(CEP, np.sum(inout < 0.5))
hitlocation[inout >= 0.5, :] = random_points_within_circle(radius, np.sum(inout >= 0.5))

# Lethal radius check
NLR = np.sum(np.sqrt(hitlocation[:, 0] ** 2 + hitlocation[:, 1] ** 2) <= LR)
P_K = 1 - (1 - P_K1) ** NumPassed

# Plot
plt.figure(figsize=(15, 7.3))
plt.plot(0, 0, '.r', markersize=30)
plt.plot(0, 0, '.w', markersize=20)
plt.plot(0, 0, '.r', markersize=8,label='Target')
plt.plot(xLR, yLR, '--b', label='Lethal Radius')
plt.plot(xCEP, yCEP, '--g', label='CEP')
plt.scatter(hitlocation[:, 0], hitlocation[:, 1], c='k', marker='*', s=50)
plt.grid(True)
plt.gca().set_aspect('equal', adjustable='box')
plt.xlim([-radius, radius])
plt.ylim([-radius, radius])
plt.text(0, 0, 'Target', ha='center', va='top', fontsize=18)

# Text annotations without underline
plt.text(radius + radius / 10, radius, f"Intercepted Warheads: {NumIntercepted}", ha='left', fontsize=14)
plt.text(radius + radius / 10, 3 / 4 * radius, f"Unintercepted Warheads: {NumPassed}", ha='left', fontsize=14)
plt.text(radius + radius / 10, 1 / 2 * radius, f"P(Kill|Remaining Warheads): {P_K:.4f}", ha='left', fontsize=14)
plt.text(radius + radius / 10, 1 / 4 * radius, f"Detonations in Lethal Radius: {NLR}", ha='left', fontsize=14)
plt.text(radius + radius / 10, 0, f"Target Destroyed: {'Yes' if NLR >= 1 else 'No'}", ha='left', fontsize=14)

plt.text(-radius - radius / 3, radius, f"Launched Warheads: {NW}", ha='right', fontsize=14)
plt.text(-radius - radius / 3, 3 / 4 * radius, f"P(Intercept Warhead): {P_I:.4f}", ha='right', fontsize=14)
plt.text(-radius - radius / 3, 1 / 2 * radius, f"P(Kill|Single Warhead): {P_K1:.4f}", ha='right', fontsize=14)
plt.text(-radius - radius / 3, 1 / 4 * radius, f"Lethal Radius: {LR:.0f} m", ha='right', fontsize=14)
plt.text(-radius - radius / 3, 0, f"Target Hardness: {H:.0f} psi", ha='right', fontsize=14)

plt.xlabel('Distance from target (m)', fontsize=18)
plt.legend(loc='lower left' if NumPassed > 0 else 'lower right', fontsize=12)
plt.show()